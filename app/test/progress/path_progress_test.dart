// M4: S2 counting (docs/05 S2), gate line, S5 prereq selection (docs/04 §2)
// and the repository bits behind them (`prereq_warned`, `stage_progress`).
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/lesson/prereq_dialog.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/lesson_status.dart';
import 'package:lta_app/progress/path_progress.dart';
import 'package:lta_app/progress/progress_repository.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

void main() {
  const a = BModule('foundation', 'a', 0, [
    BLesson('a1'),
    BLesson('a-side', main: false),
    BLesson('a2', available: false),
  ]);
  const b = BModule('foundation', 'b', 0, [
    BLesson(
      'b1',
      prereqs: [
        'foundation.l1.a1',
        'foundation.l1.a2', // not in content.lessons ("sắp có")
        'backend.l9.unknown', // not in the tree at all
        'foundation.l1.a-side',
      ],
    ),
  ]);
  const c = BModule('backend', 'c', 1, [BLesson('c1')]);
  final content = buildContent([a, b, c]);
  final stage0 = content.stages.first;

  LessonRecord rec(String id, LessonStatus s) =>
      LessonRecord(lessonId: id, status: s);
  Map<String, LessonRecord> progress(List<LessonRecord> rows) => {
    for (final r in rows) r.lessonId: r,
  };

  test('stage x/y counts main-path lessons passed', () {
    final p = progress([
      rec('foundation.l1.a1', LessonStatus.passed),
      rec('foundation.l1.a-side', LessonStatus.passed),
      rec('foundation.l1.b1', LessonStatus.read),
    ]);
    final n = stageCount(content, stage0, p);
    expect((n.done, n.total), (1, 3));
    expect(n.complete, isFalse);
  });

  test('module x/y counts every lesson, side branches included', () {
    final m = content.module('foundation/a')!;
    final p = progress([
      rec('foundation.l1.a1', LessonStatus.passed),
      rec('foundation.l1.a-side', LessonStatus.passed),
    ]);
    final n = moduleCount(m, p);
    expect((n.done, n.total), (2, 3));
    expect(moduleAllRead(m, p), isFalse);
    final all = progress([
      for (final r in m.lessons) rec(r.id, LessonStatus.passed),
    ]);
    expect(moduleCount(m, all).complete, isTrue);
    expect(moduleAllRead(m, all), isTrue);
  });

  test('module keys without a track tree are skipped', () {
    final s = PathStage(
      stage: 0,
      title: stage0.title,
      gate: 'gate0',
      outcome: null,
      modules: ['foundation/a', 'foundation/not-outlined'],
    );
    expect(stageModules(content, s).map((m) => m.key), ['foundation/a']);
  });

  test('gate state', () {
    expect(gateState(null), GateState.notTaken);
    expect(gateState(const StageRecord(stage: 0)), GateState.notTaken);
    expect(
      gateState(const StageRecord(stage: 0, attempts: 1, bestGateScore: 0.68)),
      GateState.failed,
    );
    expect(
      gateState(StageRecord(stage: 0, attempts: 2, gatePassedAt: testEpoch)),
      GateState.passed,
    );
  });

  group('S5 prereqs', () {
    final b1 = content.lessons['foundation.l1.b1']!;

    test('only openable prereqs that are not passed, in order', () {
      expect(hasOpenablePrereqs(content, b1), isTrue);
      expect(missingPrereqs(content, b1, const {}), [
        'foundation.l1.a1',
        'foundation.l1.a-side',
      ]);
      expect(
        missingPrereqs(
          content,
          b1,
          progress([rec('foundation.l1.a1', LessonStatus.passed)]),
        ),
        ['foundation.l1.a-side'],
      );
      // `read` is not enough: the dialog is about quizzes not passed.
      expect(
        missingPrereqs(
          content,
          b1,
          progress([rec('foundation.l1.a-side', LessonStatus.read)]),
        ),
        contains('foundation.l1.a-side'),
      );
    });

    test('a lesson without openable prereqs never warns', () {
      final a1 = content.lessons['foundation.l1.a1']!;
      expect(hasOpenablePrereqs(content, a1), isFalse);
      expect(missingPrereqs(content, a1, const {}), isEmpty);
    });

    test('"Quay lại" only after passing a prereq of the queued lesson', () {
      expect(
        prereqReturnTarget(content, b1.id, 'foundation.l1.a1')?.id,
        b1.id,
      );
      expect(prereqReturnTarget(content, b1.id, 'backend.l1.c1'), isNull);
      expect(prereqReturnTarget(content, null, 'foundation.l1.a1'), isNull);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late ProgressRepository repo;
    setUp(() {
      db = memoryDb();
      repo = ProgressRepository(db, FixedClock(testEpoch));
    });
    tearDown(() => db.close());

    test('prereq_warned: new row stays `new`, existing status kept', () async {
      await repo.markPrereqWarned('x');
      var r = await repo.get('x');
      expect(r!.prereqWarned, isTrue);
      expect(r.status, LessonStatus.newLesson);

      await repo.markOpened('y');
      await repo.markPrereqWarned('y');
      r = await repo.get('y');
      expect(r!.prereqWarned, isTrue);
      expect(r.status, LessonStatus.opened);
    });

    test('stage_progress rows are watched by stage', () async {
      await db
          .into(db.stageProgress)
          .insert(
            const StageProgressCompanion(
              stage: Value(0),
              bestGateScore: Value(0.68),
              attempts: Value(1),
            ),
          );
      final m = await repo.watchStages().first;
      expect(m.keys, [0]);
      expect(gateState(m[0]), GateState.failed);
      expect(m[0]!.bestGateScore, 0.68);
    });
  });
}
