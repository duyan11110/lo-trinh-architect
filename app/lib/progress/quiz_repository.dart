// Quiz persistence — docs/07 §4 (`quiz_attempt`, `quiz_answer`,
// `review_item`, `event`) and §5.3 (wrong answer → review item). Every
// answer is stored as it is checked, so a quiz survives the app being killed
// (docs/05 §10). Timestamps come from the injected Clock (DECISIONS.md E7).
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'database.dart';
import 'progress_repository.dart';
import 'review_scheduler.dart';

/// `quiz_attempt.kind`.
enum QuizKind { lesson, module, review, gate }

@immutable
class QuizAnswerRecord {
  const QuizAnswerRecord({
    required this.questionId,
    required this.answer,
    required this.correct,
  });

  final String questionId;

  /// Option ids, ordered ids, or the typed `fill` text.
  final List<String> answer;
  final bool correct;
}

@immutable
class QuizAttemptRecord {
  const QuizAttemptRecord({
    required this.id,
    required this.kind,
    required this.refId,
    required this.questionIds,
    required this.answers,
    this.finishedAt,
    this.score,
    this.total,
  });

  final int id;
  final QuizKind kind;
  final String refId;
  final List<String> questionIds;

  /// Keyed by question id.
  final Map<String, QuizAnswerRecord> answers;
  final DateTime? finishedAt;
  final int? score;
  final int? total;

  bool get finished => finishedAt != null;

  /// Finished by "Thoát": no score recorded (docs/05 S4).
  bool get abandoned => finished && score == null;
}

class QuizRepository {
  QuizRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// The unfinished attempt of [kind]/[refId] over exactly [questionIds]
  /// (an app kill mid-quiz), or a new one.
  Future<QuizAttemptRecord> startOrResume(
    QuizKind kind,
    String refId,
    List<String> questionIds,
  ) => _db.transaction(() async {
    final ids = jsonEncode(questionIds);
    final open =
        await (_db.select(_db.quizAttempt)
              ..where(
                (t) =>
                    t.kind.equals(kind.name) &
                    t.refId.equals(refId) &
                    t.finishedAt.isNull() &
                    t.questionIds.equals(ids),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (open != null) return (await attempt(open.id))!;
    final id = await _db
        .into(_db.quizAttempt)
        .insert(
          QuizAttemptCompanion.insert(
            kind: kind.name,
            refId: refId,
            startedAt: isoUtc(_clock.now()),
            questionIds: ids,
          ),
        );
    return QuizAttemptRecord(
      id: id,
      kind: kind,
      refId: refId,
      questionIds: List.unmodifiable(questionIds),
      answers: const {},
    );
  });

  Future<QuizAttemptRecord?> attempt(int id) async {
    final row = await (_db.select(
      _db.quizAttempt,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final rows = await (_db.select(
      _db.quizAnswer,
    )..where((t) => t.attemptId.equals(id))).get();
    return QuizAttemptRecord(
      id: row.id,
      kind: QuizKind.values.byName(row.kind),
      refId: row.refId,
      questionIds: List.unmodifiable(
        (jsonDecode(row.questionIds) as List).cast<String>(),
      ),
      answers: {
        for (final a in rows)
          a.questionId: QuizAnswerRecord(
            questionId: a.questionId,
            answer: List.unmodifiable(
              (jsonDecode(a.answer) as List).cast<String>(),
            ),
            correct: a.correct != 0,
          ),
      },
      finishedAt: row.finishedAt == null ? null : DateTime.parse(row.finishedAt!),
      score: row.score,
      total: row.total,
    );
  }

  /// Stores one checked answer. A wrong answer outside a gate creates or
  /// resets the question's `review_item` (docs/07 §5.3; gate questions never
  /// enter review). [sourceLesson] is the lesson the question belongs to.
  Future<void> recordAnswer({
    required int attemptId,
    required QuizKind kind,
    required String questionId,
    required List<String> answer,
    required bool correct,
    required String? sourceLesson,
  }) => _db.transaction(() async {
    final now = _clock.now();
    await _db
        .into(_db.quizAnswer)
        .insertOnConflictUpdate(
          QuizAnswerCompanion.insert(
            attemptId: attemptId,
            questionId: questionId,
            answer: jsonEncode(answer),
            correct: correct ? 1 : 0,
            answeredAt: isoUtc(now),
          ),
        );
    if (!correct && kind != QuizKind.gate) {
      await _reviewWrong(questionId, sourceLesson, now);
    }
  });

  Future<void> _reviewWrong(
    String questionId,
    String? sourceLesson,
    DateTime now,
  ) async {
    final row = await (_db.select(
      _db.reviewItem,
    )..where((t) => t.itemId.equals(questionId))).getSingleOrNull();
    final before = row == null
        ? null
        : ReviewState(
            tier: row.tier,
            dueAt: DateTime.parse(row.dueAt),
            lastResult: row.lastResult,
            retired: row.retired != 0,
          );
    final next = ReviewScheduler.onWrong(before, now);
    if (next == before) return;
    await _db
        .into(_db.reviewItem)
        .insertOnConflictUpdate(
          ReviewItemCompanion(
            itemId: Value(questionId),
            kind: const Value('question'),
            sourceLesson: Value(row?.sourceLesson ?? sourceLesson),
            tier: Value(next.tier),
            dueAt: Value(isoUtc(next.dueAt)),
            lastResult: Value(next.lastResult),
            timesSeen: Value(row?.timesSeen ?? 0),
            retired: Value(next.retired ? 1 : 0),
          ),
        );
  }

  /// Completes the attempt with its score and logs `quiz_finished`
  /// (value = score / total).
  Future<void> finish(int attemptId, {required int score, required int total}) =>
      _db.transaction(() async {
        final now = isoUtc(_clock.now());
        final row = await (_db.select(
          _db.quizAttempt,
        )..where((t) => t.id.equals(attemptId))).getSingle();
        await (_db.update(
          _db.quizAttempt,
        )..where((t) => t.id.equals(attemptId))).write(
          QuizAttemptCompanion(
            finishedAt: Value(now),
            score: Value(score),
            total: Value(total),
          ),
        );
        await _db
            .into(_db.event)
            .insert(
              EventCompanion.insert(
                ts: now,
                kind: 'quiz_finished',
                ref: Value(row.refId),
                value: Value(total == 0 ? 0 : score / total),
              ),
            );
      });

  /// "Thoát": closes the attempt without a score (docs/05 S4: "điểm không
  /// được tính"); answers and review items stay.
  Future<void> abandon(int attemptId) =>
      (_db.update(_db.quizAttempt)..where(
            (t) => t.id.equals(attemptId) & t.finishedAt.isNull(),
          ))
          .write(QuizAttemptCompanion(finishedAt: Value(isoUtc(_clock.now()))));
}

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(appDatabaseProvider), ref.watch(clockProvider)),
);

final quizAttemptProvider = FutureProvider.autoDispose
    .family<QuizAttemptRecord?, int>(
      (ref, id) => ref.watch(quizRepositoryProvider).attempt(id),
    );
