// Gate exam and module quiz attempts — docs/07 §4 (`quiz_attempt` kinds
// `gate` / `module`, `quiz_answer.flagged`, `stage_progress`, `event`),
// §5.4 and §5.5. Draws come from gate_sampler.dart / module_quiz_sampler.dart
// seeded with the attempt id; time and randomness are injected (E7).
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/models/models.dart';
import 'clock.dart';
import 'database.dart';
import 'gate_sampler.dart';
import 'module_quiz_sampler.dart';
import 'path_progress.dart';
import 'progress_repository.dart';
import 'quiz_repository.dart';

/// A paused gate exam can be resumed for this long (docs/05 S4).
const Duration gatePauseWindow = Duration(hours: 24);

/// One finished gate attempt (S8 history).
@immutable
class GateHistoryEntry {
  const GateHistoryEntry({
    required this.attemptId,
    required this.finishedAt,
    required this.score,
    required this.total,
  });

  final int attemptId;
  final DateTime finishedAt;
  final int score;
  final int total;

  double get ratio => total == 0 ? 0 : score / total;
  bool get passed => ratio >= gatePassRatio;
}

/// An unfinished quiz with at least one answer (S1 "Tiếp tục quiz").
@immutable
class OpenQuiz {
  const OpenQuiz({
    required this.attemptId,
    required this.kind,
    required this.refId,
    required this.answered,
    required this.total,
  });

  final int attemptId;
  final QuizKind kind;
  final String refId;
  final int answered;
  final int total;
}

class ExamRepository {
  ExamRepository(this._db, this._clock, this._quiz, this._randomFor);

  final AppDatabase _db;
  final Clock _clock;
  final QuizRepository _quiz;
  final Random Function(int seed) _randomFor;

  Future<QuizAttemptData?> _open(QuizKind kind, String refId) =>
      (_db.select(_db.quizAttempt)
            ..where(
              (t) =>
                  t.kind.equals(kind.name) &
                  t.refId.equals(refId) &
                  t.finishedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  /// Last activity of an attempt: its newest answer, else its start.
  Future<DateTime> _lastActivity(QuizAttemptData row) async {
    final last = await _db
        .customSelect(
          'SELECT MAX(answered_at) AS t FROM quiz_answer WHERE attempt_id = ?',
          variables: [Variable.withInt(row.id)],
        )
        .getSingle();
    return DateTime.parse(last.read<String?>('t') ?? row.startedAt);
  }

  Future<bool> _resumable(QuizAttemptData row) async =>
      _clock.now().difference(await _lastActivity(row)) < gatePauseWindow;

  /// The paused exam of [gate] still inside the 24-hour window, if any.
  Future<QuizAttemptRecord?> pausedGate(Gate gate) async {
    final row = await _open(QuizKind.gate, gate.gate);
    if (row == null || !await _resumable(row)) return null;
    return _quiz.attempt(row.id);
  }

  /// Resumes the paused exam (≤ 24 h) or draws a new one (docs/07 §5.4);
  /// a stale paused exam is closed without a score.
  Future<QuizAttemptRecord> startGate(Content content, Gate gate) =>
      _db.transaction(() async {
        final open = await _open(QuizKind.gate, gate.gate);
        if (open != null) {
          if (await _resumable(open)) return (await _quiz.attempt(open.id))!;
          await _quiz.abandon(open.id);
        }
        final last =
            await (_db.select(_db.quizAttempt)
                  ..where(
                    (t) =>
                        t.kind.equals(QuizKind.gate.name) &
                        t.refId.equals(gate.gate),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.id)])
                  ..limit(1))
                .getSingleOrNull();
        final lastUsed = last == null
            ? const <String>[]
            : (jsonDecode(last.questionIds) as List).cast<String>();
        final id = await _insert(QuizKind.gate, gate.gate);
        final ids = GateSampler.sample(
          content: content,
          gate: gate,
          random: _randomFor(id),
          lastUsed: lastUsed,
        );
        await _setQuestions(id, ids);
        return (await _quiz.attempt(id))!;
      });

  /// Resumes the unfinished module quiz whose questions all still exist, or
  /// draws a new one (docs/07 §5.5).
  Future<QuizAttemptRecord> startModule(Content content, TrackModule module) =>
      _db.transaction(() async {
        final known = ModuleQuizSampler.lessonOfQuestion(content, module);
        final open = await _open(QuizKind.module, module.key);
        if (open != null) {
          final ids = (jsonDecode(open.questionIds) as List).cast<String>();
          if (ids.isNotEmpty && ids.every(known.containsKey)) {
            return (await _quiz.attempt(open.id))!;
          }
          await _quiz.abandon(open.id);
        }
        final wrong = await _db
            .customSelect(
              'SELECT DISTINCT question_id FROM quiz_answer WHERE correct = 0',
            )
            .get();
        final id = await _insert(QuizKind.module, module.key);
        final ids = ModuleQuizSampler.sample(
          content: content,
          module: module,
          random: _randomFor(id),
          wrongBefore: {
            for (final r in wrong)
              if (known.containsKey(r.read<String>('question_id')))
                r.read<String>('question_id'),
          },
        );
        await _setQuestions(id, ids);
        return (await _quiz.attempt(id))!;
      });

  Future<int> _insert(QuizKind kind, String refId) => _db
      .into(_db.quizAttempt)
      .insert(
        QuizAttemptCompanion.insert(
          kind: kind.name,
          refId: refId,
          startedAt: isoUtc(_clock.now()),
          questionIds: '[]',
        ),
      );

  Future<void> _setQuestions(int id, List<String> ids) =>
      (_db.update(_db.quizAttempt)..where((t) => t.id.equals(id))).write(
        QuizAttemptCompanion(questionIds: Value(jsonEncode(ids))),
      );

  /// Gate: "Đánh dấu xem lại". An unanswered question gets an empty, wrong
  /// answer row carrying the flag.
  Future<void> setFlag(int attemptId, String questionId, bool flagged) =>
      _db.transaction(() async {
        await _db
            .into(_db.quizAnswer)
            .insert(
              QuizAnswerCompanion.insert(
                attemptId: attemptId,
                questionId: questionId,
                answer: '[]',
                correct: 0,
                answeredAt: isoUtc(_clock.now()),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await (_db.update(_db.quizAnswer)..where(
              (t) =>
                  t.attemptId.equals(attemptId) &
                  t.questionId.equals(questionId),
            ))
            .write(QuizAnswerCompanion(flagged: Value(flagged ? 1 : 0)));
      });

  Future<Set<String>> flagged(int attemptId) async {
    final rows = await (_db.select(_db.quizAnswer)..where(
          (t) => t.attemptId.equals(attemptId) & t.flagged.equals(1),
        ))
        .get();
    return {for (final r in rows) r.questionId};
  }

  /// Scores the exam: correct / N; ≥ 75% → `stage_progress.gate_passed_at`
  /// (docs/07 §5.4). Updates attempts and best score; logs `gate_finished`.
  Future<GateHistoryEntry> finishGate(int attemptId, int stage) =>
      _db.transaction(() async {
        final a = (await _quiz.attempt(attemptId))!;
        final total = a.questionIds.length;
        final score = a.questionIds
            .where((id) => a.answers[id]?.correct ?? false)
            .length;
        final now = _clock.now();
        await (_db.update(
          _db.quizAttempt,
        )..where((t) => t.id.equals(attemptId))).write(
          QuizAttemptCompanion(
            finishedAt: Value(isoUtc(now)),
            score: Value(score),
            total: Value(total),
          ),
        );
        final ratio = total == 0 ? 0.0 : score / total;
        final row = await (_db.select(
          _db.stageProgress,
        )..where((t) => t.stage.equals(stage))).getSingleOrNull();
        final passed = ratio >= gatePassRatio;
        await _db
            .into(_db.stageProgress)
            .insertOnConflictUpdate(
              StageProgressCompanion(
                stage: Value(stage),
                gatePassedAt: Value(
                  row?.gatePassedAt ?? (passed ? isoUtc(now) : null),
                ),
                bestGateScore: Value(
                  row?.bestGateScore == null
                      ? ratio
                      : max(ratio, row!.bestGateScore!),
                ),
                attempts: Value((row?.attempts ?? 0) + 1),
              ),
            );
        await _db
            .into(_db.event)
            .insert(
              EventCompanion.insert(
                ts: isoUtc(now),
                kind: 'gate_finished',
                ref: Value(a.refId),
                value: Value(ratio),
              ),
            );
        return GateHistoryEntry(
          attemptId: attemptId,
          finishedAt: now,
          score: score,
          total: total,
        );
      });

  /// Finished, scored attempts of [gateId], newest first.
  Stream<List<GateHistoryEntry>> watchGateHistory(String gateId) {
    final q = _db.select(_db.quizAttempt)
      ..where(
        (t) =>
            t.kind.equals(QuizKind.gate.name) &
            t.refId.equals(gateId) &
            t.finishedAt.isNotNull() &
            t.score.isNotNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.id)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          GateHistoryEntry(
            attemptId: r.id,
            finishedAt: DateTime.parse(r.finishedAt!),
            score: r.score!,
            total: r.total ?? 0,
          ),
      ],
    );
  }

  /// `track/module` keys with a finished module quiz ≥ 70% ("Module ✓").
  Stream<Set<String>> watchPassedModules() {
    final q = _db.select(_db.quizAttempt)
      ..where(
        (t) =>
            t.kind.equals(QuizKind.module.name) &
            t.finishedAt.isNotNull() &
            t.score.isNotNull(),
      );
    return q.watch().map(
      (rows) => {
        for (final r in rows)
          if ((r.total ?? 0) > 0 &&
              r.score! / r.total! >= ModuleQuizSampler.passRatio)
            r.refId,
      },
    );
  }

  /// Newest unfinished lesson/module/gate quiz with ≥ 1 answer (docs/05
  /// §10 "Tiếp tục quiz"); a gate only inside its 24-hour window.
  Stream<OpenQuiz?> watchOpenQuiz() {
    final q = _db.customSelect(
      'SELECT a.id, a.kind, a.ref_id, a.started_at, a.question_ids, '
      'COUNT(q.question_id) AS answered, MAX(q.answered_at) AS last '
      'FROM quiz_attempt a JOIN quiz_answer q ON q.attempt_id = a.id '
      "WHERE a.finished_at IS NULL AND a.kind IN ('lesson', 'module', 'gate') "
      "AND q.answer <> '[]' "
      'GROUP BY a.id ORDER BY a.id DESC',
      readsFrom: {_db.quizAttempt, _db.quizAnswer},
    );
    return q.watch().map((rows) {
      final now = _clock.now();
      for (final r in rows) {
        final kind = QuizKind.values.byName(r.read<String>('kind'));
        final last = DateTime.parse(
          r.read<String?>('last') ?? r.read<String>('started_at'),
        );
        if (kind == QuizKind.gate && now.difference(last) >= gatePauseWindow) {
          continue;
        }
        return OpenQuiz(
          attemptId: r.read<int>('id'),
          kind: kind,
          refId: r.read<String>('ref_id'),
          answered: r.read<int>('answered'),
          total: (jsonDecode(r.read<String>('question_ids')) as List).length,
        );
      }
      return null;
    });
  }
}

/// Seeds draws with the attempt id (docs/07 §5.4); tests pin it (E7).
final examRandomProvider = Provider<Random Function(int seed)>(
  (ref) => Random.new,
);

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(quizRepositoryProvider),
    ref.watch(examRandomProvider),
  ),
);

final gateHistoryProvider =
    StreamProvider.family<List<GateHistoryEntry>, String>(
      (ref, gateId) => ref.watch(examRepositoryProvider).watchGateHistory(gateId),
    );

final passedModulesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(examRepositoryProvider).watchPassedModules(),
);

final openQuizProvider = StreamProvider<OpenQuiz?>(
  (ref) => ref.watch(examRepositoryProvider).watchOpenQuiz(),
);
