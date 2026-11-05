// Lesson progress — docs/07 §4 (`lesson_progress`, `vocab_seen`, `event`,
// `stage_progress`) and §5.1 (state transitions). All timestamps come from
// the injected [Clock] (DECISIONS.md E7) and are stored as ISO 8601 UTC.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'database.dart';
import 'lesson_status.dart';

/// Lesson quiz pass mark (docs/07 §5.1: ≥ 70%).
const double lessonPassRatio = 0.7;

/// Immutable view of one `lesson_progress` row.
@immutable
class LessonRecord {
  const LessonRecord({
    required this.lessonId,
    this.status = LessonStatus.newLesson,
    this.firstOpenedAt,
    this.readAt,
    this.passedAt,
    this.bestScore,
    this.scrollRatio = 0,
    this.prereqWarned = false,
    this.contentVersion,
  });

  factory LessonRecord.fromRow(LessonProgressData r) => LessonRecord(
    lessonId: r.lessonId!,
    status: LessonStatus.fromDb(r.status),
    firstOpenedAt: _parse(r.firstOpenedAt),
    readAt: _parse(r.readAt),
    passedAt: _parse(r.passedAt),
    bestScore: r.bestScore,
    scrollRatio: r.scrollRatio,
    prereqWarned: r.prereqWarned != 0,
    contentVersion: r.contentVersion,
  );

  static DateTime? _parse(String? s) => s == null ? null : DateTime.parse(s);

  final String lessonId;
  final LessonStatus status;
  final DateTime? firstOpenedAt;
  final DateTime? readAt;
  final DateTime? passedAt;

  /// 0..1.
  final double? bestScore;
  final double scrollRatio;
  final bool prereqWarned;

  /// Lesson `content_version` when it was passed.
  final int? contentVersion;

  /// docs/07 §5.1: passed, but the lesson changed since → "đã cập nhật".
  bool isUpdatedSincePassed(int lessonContentVersion) =>
      status == LessonStatus.passed &&
      contentVersion != null &&
      lessonContentVersion > contentVersion!;
}

/// Latest finished lesson quiz (for "Lần trước: 4/6").
@immutable
class QuizScore {
  const QuizScore(this.score, this.total);
  final int score;
  final int total;
}

/// One `stage_progress` row (gate state on S2).
@immutable
class StageRecord {
  const StageRecord({
    required this.stage,
    this.gatePassedAt,
    this.bestGateScore,
    this.attempts = 0,
  });

  final int stage;
  final DateTime? gatePassedAt;

  /// 0..1.
  final double? bestGateScore;
  final int attempts;

  bool get gatePassed => gatePassedAt != null;
}

class ProgressRepository {
  ProgressRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  String _now() => isoUtc(_clock.now());

  Future<LessonRecord?> get(String lessonId) async {
    final row = await _rowQuery(lessonId).getSingleOrNull();
    return row == null ? null : LessonRecord.fromRow(row);
  }

  /// Every row, keyed by lesson id. Lessons without a row are `new`.
  Stream<Map<String, LessonRecord>> watchAll() =>
      _db.select(_db.lessonProgress).watch().map(
        (rows) => {
          for (final r in rows) r.lessonId!: LessonRecord.fromRow(r),
        },
      );

  /// Stages whose gate has been passed (`stage_progress.gate_passed_at`).
  Stream<Set<int>> watchPassedGates() {
    final q = _db.select(_db.stageProgress)
      ..where((t) => t.gatePassedAt.isNotNull());
    return q.watch().map((rows) => {for (final r in rows) r.stage});
  }

  /// Every `stage_progress` row, keyed by stage.
  Stream<Map<int, StageRecord>> watchStages() =>
      _db.select(_db.stageProgress).watch().map(
        (rows) => {
          for (final r in rows)
            r.stage: StageRecord(
              stage: r.stage,
              gatePassedAt: LessonRecord._parse(r.gatePassedAt),
              bestGateScore: r.bestGateScore,
              attempts: r.attempts,
            ),
        },
      );

  /// S5 was shown for [lessonId]: `prereq_warned = 1` so it never shows
  /// again (docs/05 S5). Creates a `new` row when there is none; the status
  /// is left alone.
  Future<void> markPrereqWarned(String lessonId) => _db.transaction(() async {
    final row = await _rowQuery(lessonId).getSingleOrNull();
    if (row == null) {
      await _db
          .into(_db.lessonProgress)
          .insert(
            LessonProgressCompanion.insert(
              lessonId: Value(lessonId),
              status: LessonStatus.newLesson.db,
              prereqWarned: const Value(1),
            ),
          );
    } else {
      await _update(
        lessonId,
        const LessonProgressCompanion(prereqWarned: Value(1)),
      );
    }
  });

  /// Latest finished `lesson` quiz attempt for [lessonId], if any.
  Stream<QuizScore?> watchLastLessonScore(String lessonId) {
    final q = _db.select(_db.quizAttempt)
      ..where(
        (t) =>
            t.kind.equals('lesson') &
            t.refId.equals(lessonId) &
            t.finishedAt.isNotNull() &
            t.score.isNotNull() &
            t.total.isNotNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.finishedAt)])
      ..limit(1);
    return q.watchSingleOrNull().map(
      (r) => r == null ? null : QuizScore(r.score!, r.total!),
    );
  }

  /// Opening a lesson: `new → opened` (+`first_opened_at`); anything higher
  /// is left alone. Logs `lesson_opened` every time.
  Future<void> markOpened(String lessonId) => _db.transaction(() async {
    final now = _now();
    final row = await _rowQuery(lessonId).getSingleOrNull();
    final status = LessonStatus.fromDb(row?.status);
    if (row == null) {
      await _db
          .into(_db.lessonProgress)
          .insert(
            LessonProgressCompanion.insert(
              lessonId: Value(lessonId),
              status: LessonStatus.opened.db,
              firstOpenedAt: Value(now),
            ),
          );
    } else if (status == LessonStatus.newLesson) {
      await _update(
        lessonId,
        LessonProgressCompanion(
          status: Value(LessonStatus.opened.db),
          firstOpenedAt: Value(row.firstOpenedAt ?? now),
        ),
      );
    }
    await _event('lesson_opened', lessonId, now);
  });

  /// Summary reached or "Đánh dấu đã đọc, quiz sau": `new|opened → read`
  /// (+`read_at`), every [vocab] term into `vocab_seen` (first lesson wins).
  /// Returns whether the status changed.
  Future<bool> markRead(String lessonId, {List<String> vocab = const []}) =>
      _db.transaction(() async {
        final now = _now();
        final row = await _rowQuery(lessonId).getSingleOrNull();
        final status = LessonStatus.fromDb(row?.status);
        if (status.atLeast(LessonStatus.read)) return false;
        await _db
            .into(_db.lessonProgress)
            .insertOnConflictUpdate(
              LessonProgressCompanion(
                lessonId: Value(lessonId),
                status: Value(LessonStatus.read.db),
                firstOpenedAt: Value(row?.firstOpenedAt ?? now),
                readAt: Value(now),
              ),
            );
        for (final term in vocab) {
          await _db
              .into(_db.vocabSeen)
              .insert(
                VocabSeenCompanion.insert(
                  term: Value(term),
                  firstLessonId: lessonId,
                  seenAt: now,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        await _event('lesson_read', lessonId, now);
        return true;
      });

  /// Lesson quiz finished with [ratio] (0..1): ≥ 70% → `passed`
  /// (+`passed_at` first time, `content_version`); below → status unchanged.
  /// `best_score` keeps the maximum. Never downgrades.
  Future<void> recordQuizScore(
    String lessonId, {
    required double ratio,
    required int contentVersion,
  }) => _db.transaction(() async {
    final now = _now();
    final row = await _rowQuery(lessonId).getSingleOrNull();
    final status = LessonStatus.fromDb(row?.status);
    final best = row?.bestScore == null
        ? ratio
        : (ratio > row!.bestScore! ? ratio : row.bestScore!);
    final passed = ratio >= lessonPassRatio;
    final next = passed ? status.raiseTo(LessonStatus.passed) : status;
    await _db
        .into(_db.lessonProgress)
        .insertOnConflictUpdate(
          LessonProgressCompanion(
            lessonId: Value(lessonId),
            status: Value(next.db),
            firstOpenedAt: Value(row?.firstOpenedAt),
            readAt: Value(row?.readAt),
            passedAt: Value(row?.passedAt ?? (passed ? now : null)),
            bestScore: Value(best),
            scrollRatio: Value(row?.scrollRatio ?? 0),
            prereqWarned: Value(row?.prereqWarned ?? 0),
            contentVersion: Value(passed ? contentVersion : row?.contentVersion),
          ),
        );
  });

  /// Remembers where the reader stopped (`scroll_ratio`, docs/05 S3).
  Future<void> saveScroll(String lessonId, double ratio) =>
      _update(
        lessonId,
        LessonProgressCompanion(scrollRatio: Value(ratio.clamp(0.0, 1.0))),
      );

  SimpleSelectStatement<LessonProgress, LessonProgressData> _rowQuery(
    String lessonId,
  ) =>
      _db.select(_db.lessonProgress)
        ..where((t) => t.lessonId.equals(lessonId));

  Future<void> _update(String lessonId, LessonProgressCompanion c) =>
      (_db.update(_db.lessonProgress)
            ..where((t) => t.lessonId.equals(lessonId)))
          .write(c);

  Future<void> _event(String kind, String ref, String ts) => _db
      .into(_db.event)
      .insert(EventCompanion.insert(ts: ts, kind: kind, ref: Value(ref)));
}

/// The progress database. Override with an in-memory database in tests.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final lessonProgressProvider = StreamProvider<Map<String, LessonRecord>>(
  (ref) => ref.watch(progressRepositoryProvider).watchAll(),
);

final passedGatesProvider = StreamProvider<Set<int>>(
  (ref) => ref.watch(progressRepositoryProvider).watchPassedGates(),
);

final lastLessonScoreProvider = StreamProvider.family<QuizScore?, String>(
  (ref, lessonId) =>
      ref.watch(progressRepositoryProvider).watchLastLessonScore(lessonId),
);

final stageProgressProvider = StreamProvider<Map<int, StageRecord>>(
  (ref) => ref.watch(progressRepositoryProvider).watchStages(),
);
