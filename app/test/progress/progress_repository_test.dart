// docs/07 §9 Unit `progress`: status transitions never downgrade (§5.1),
// timestamps from the injected Clock (DECISIONS.md E7).
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/lesson_status.dart';
import 'package:lta_app/progress/progress_repository.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late ProgressRepository repo;
  const id = 'foundation.l1.sample';

  setUp(() {
    db = memoryDb();
    clock = FixedClock(testEpoch);
    repo = ProgressRepository(db, clock);
  });
  tearDown(() => db.close());

  Future<List<String>> events() async =>
      [for (final e in await db.select(db.event).get()) '${e.kind}:${e.ref}'];

  test('unknown lesson has no row (= new)', () async {
    expect(await repo.get(id), isNull);
  });

  test('open: new → opened with first_opened_at; reopening keeps it', () async {
    await repo.markOpened(id);
    var p = (await repo.get(id))!;
    expect(p.status, LessonStatus.opened);
    expect(p.firstOpenedAt, testEpoch);

    clock.advance(const Duration(hours: 3));
    await repo.markOpened(id);
    p = (await repo.get(id))!;
    expect(p.status, LessonStatus.opened);
    expect(p.firstOpenedAt, testEpoch);
    expect(await events(), ['lesson_opened:$id', 'lesson_opened:$id']);
  });

  test('timestamps are stored as ISO 8601 UTC', () async {
    clock.set(DateTime.parse('2026-11-05T10:30:00+07:00'));
    await repo.markOpened(id);
    final row = await db.select(db.lessonProgress).getSingle();
    expect(row.firstOpenedAt, '2026-11-05T03:30:00.000Z');
  });

  test('read: opened → read, read_at, vocab_seen (first lesson wins)', () async {
    await repo.markOpened(id);
    clock.advance(const Duration(minutes: 12));
    expect(await repo.markRead(id, vocab: ['header', 'status-code']), isTrue);

    final p = (await repo.get(id))!;
    expect(p.status, LessonStatus.read);
    expect(p.readAt, testEpoch.add(const Duration(minutes: 12)));
    expect(p.firstOpenedAt, testEpoch);

    await repo.markRead('other.lesson', vocab: ['header']);
    final seen = {
      for (final v in await db.select(db.vocabSeen).get())
        v.term: v.firstLessonId,
    };
    expect(seen, {'header': id, 'status-code': id});
    expect(await events(), [
      'lesson_opened:$id',
      'lesson_read:$id',
      'lesson_read:other.lesson',
    ]);
  });

  test('read without opening first creates the row', () async {
    await repo.markRead(id);
    final p = (await repo.get(id))!;
    expect(p.status, LessonStatus.read);
    expect(p.firstOpenedAt, testEpoch);
  });

  test('read twice is a no-op the second time', () async {
    await repo.markRead(id);
    clock.advance(const Duration(days: 1));
    expect(await repo.markRead(id), isFalse);
    expect((await repo.get(id))!.readAt, testEpoch);
  });

  test('quiz < 70% keeps read; ≥ 70% → passed with content_version', () async {
    await repo.markRead(id);
    await repo.recordQuizScore(id, ratio: 4 / 6, contentVersion: 3);
    var p = (await repo.get(id))!;
    expect(p.status, LessonStatus.read);
    expect(p.bestScore, closeTo(4 / 6, 1e-9));
    expect(p.passedAt, isNull);

    clock.advance(const Duration(hours: 1));
    await repo.recordQuizScore(id, ratio: 5 / 6, contentVersion: 3);
    p = (await repo.get(id))!;
    expect(p.status, LessonStatus.passed);
    expect(p.passedAt, testEpoch.add(const Duration(hours: 1)));
    expect(p.contentVersion, 3);
    expect(p.bestScore, closeTo(5 / 6, 1e-9));
    expect(p.readAt, testEpoch);
  });

  test('exactly 70% passes', () async {
    await repo.recordQuizScore(id, ratio: 0.7, contentVersion: 1);
    expect((await repo.get(id))!.status, LessonStatus.passed);
  });

  test('never downgrades a passed lesson', () async {
    await repo.markRead(id);
    await repo.recordQuizScore(id, ratio: 1, contentVersion: 2);
    final passedAt = (await repo.get(id))!.passedAt;

    clock.advance(const Duration(days: 2));
    await repo.markOpened(id);
    expect(await repo.markRead(id), isFalse);
    await repo.recordQuizScore(id, ratio: 0.2, contentVersion: 2);

    final p = (await repo.get(id))!;
    expect(p.status, LessonStatus.passed);
    expect(p.passedAt, passedAt);
    expect(p.bestScore, 1);
    expect(p.contentVersion, 2);
  });

  test('"đã cập nhật" when the lesson content_version grew', () async {
    await repo.recordQuizScore(id, ratio: 1, contentVersion: 2);
    final p = (await repo.get(id))!;
    expect(p.isUpdatedSincePassed(2), isFalse);
    expect(p.isUpdatedSincePassed(3), isTrue);
    expect(
      const LessonRecord(lessonId: id, status: LessonStatus.read)
          .isUpdatedSincePassed(3),
      isFalse,
    );
  });

  test('scroll ratio is saved and clamped', () async {
    await repo.markOpened(id);
    await repo.saveScroll(id, 0.42);
    expect((await repo.get(id))!.scrollRatio, closeTo(0.42, 1e-9));
    await repo.saveScroll(id, 1.3);
    expect((await repo.get(id))!.scrollRatio, 1);
  });

  test('watchAll emits status changes', () async {
    final seen = <LessonStatus?>[];
    final sub = repo.watchAll().listen((m) => seen.add(m[id]?.status));
    await pumpEventQueue();
    await repo.markOpened(id);
    await pumpEventQueue();
    await repo.markRead(id);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [null, LessonStatus.opened, LessonStatus.read]);
  });

  test('last lesson score = latest finished attempt', () async {
    Future<void> attempt(String finished, int score, {String ref = id}) => db
        .into(db.quizAttempt)
        .insert(
          QuizAttemptCompanion.insert(
            kind: 'lesson',
            refId: ref,
            startedAt: finished,
            finishedAt: Value(finished),
            score: Value(score),
            total: const Value(6),
            questionIds: '[]',
          ),
        );
    expect(await repo.watchLastLessonScore(id).first, isNull);
    await attempt('2026-11-01T00:00:00.000Z', 3);
    await attempt('2026-11-03T00:00:00.000Z', 4);
    await attempt('2026-11-04T00:00:00.000Z', 6, ref: 'x');
    await db
        .into(db.quizAttempt)
        .insert(
          QuizAttemptCompanion.insert(
            kind: 'lesson',
            refId: id,
            startedAt: '2026-11-05T00:00:00.000Z',
            questionIds: '[]',
          ),
        );
    final last = await repo.watchLastLessonScore(id).first;
    expect((last!.score, last.total), (4, 6));
  });

  test('passed gates come from stage_progress.gate_passed_at', () async {
    await db
        .into(db.stageProgress)
        .insert(
          StageProgressCompanion.insert(
            stage: const Value(0),
            gatePassedAt: const Value('2026-11-01T00:00:00.000Z'),
          ),
        );
    await db
        .into(db.stageProgress)
        .insert(StageProgressCompanion.insert(stage: const Value(1)));
    expect(await repo.watchPassedGates().first, {0});
  });
}
