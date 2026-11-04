// docs/07 §9 Unit `progress`: "Học tiếp" skips `read`; counting to the gate
// (§5.2); "Bài x/y trong module" counts side branches (DECISIONS.md E7).
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/progress/learning_plan.dart';
import 'package:lta_app/progress/lesson_status.dart';
import 'package:lta_app/progress/progress_repository.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

void main() {
  // Stage 0: a(3 main + 1 side), b(2 main, 1 not yet in content)
  // Stage 1: c(2 main)
  const a = BModule('foundation', 'a', 0, [
    BLesson('a1'),
    BLesson('a2'),
    BLesson('a-side', main: false),
    BLesson('a3'),
  ]);
  const b = BModule('foundation', 'b', 0, [
    BLesson('b1', available: false),
    BLesson('b2'),
  ]);
  const c = BModule('backend', 'c', 1, [BLesson('c1'), BLesson('c2')]);
  final content = buildContent([a, b, c]);
  String id(BModule m, String slug) => '${m.track}.l1.$slug';

  LessonRecord rec(
    String id,
    LessonStatus s, {
    int openedMin = 0,
    int readMin = 0,
  }) => LessonRecord(
    lessonId: id,
    status: s,
    firstOpenedAt: testEpoch.add(Duration(minutes: openedMin)),
    readAt: s.atLeast(LessonStatus.read)
        ? testEpoch.add(Duration(minutes: readMin))
        : null,
  );

  LearningPlan plan(List<LessonRecord> rows, {Set<int> gates = const {}}) =>
      LearningPlan.compute(content, {for (final r in rows) r.lessonId: r}, gates);

  test('main path follows path order, main_path lessons only', () {
    expect(buildMainPath(content).map((e) => e.id), [
      id(a, 'a1'),
      id(a, 'a2'),
      id(a, 'a3'),
      id(b, 'b1'),
      id(b, 'b2'),
      id(c, 'c1'),
      id(c, 'c2'),
    ]);
    expect(buildMainPath(content).map((e) => e.stage), [0, 0, 0, 0, 0, 1, 1]);
  });

  test('fresh install: first lesson, stage 0, all main lessons to go', () {
    final p = plan([]);
    expect(p.fresh, isTrue);
    expect(p.next!.id, id(a, 'a1'));
    expect(p.currentStage, 0);
    expect(p.remainingToGate, 5);
    expect(p.gateReady, isFalse);
    expect(p.finished, isFalse);
    expect(p.pendingQuiz, isEmpty);
  });

  test('Học tiếp skips read and passed lessons', () {
    final p = plan([
      rec(id(a, 'a1'), LessonStatus.passed),
      rec(id(a, 'a2'), LessonStatus.read),
    ]);
    expect(p.fresh, isFalse);
    expect(p.next!.id, id(a, 'a3'));
  });

  test('side branches are never Học tiếp', () {
    final p = plan([
      rec(id(a, 'a1'), LessonStatus.read),
      rec(id(a, 'a2'), LessonStatus.read),
      rec(id(a, 'a-side'), LessonStatus.opened, openedMin: 9),
    ]);
    expect(p.next!.id, id(a, 'a3'));
  });

  test('lessons not in content.lessons are skipped but still counted', () {
    final p = plan([
      for (final s in ['a1', 'a2', 'a3']) rec(id(a, s), LessonStatus.passed),
    ]);
    expect(p.next!.id, id(b, 'b2'));
    expect(p.remainingToGate, 2); // b1 (upcoming) + b2
  });

  test('prefers the most recently opened lesson in the same module', () {
    final p = plan([
      rec(id(a, 'a2'), LessonStatus.opened, openedMin: 5),
      rec(id(a, 'a3'), LessonStatus.opened, openedMin: 10),
    ]);
    expect(p.next!.id, id(a, 'a3'));
  });

  test('a recently opened lesson in another module does not jump ahead', () {
    final p = plan([rec(id(c, 'c2'), LessonStatus.opened, openedMin: 30)]);
    expect(p.next!.id, id(a, 'a1'));
    expect(p.inProgress, [id(c, 'c2')]);
  });

  test('"Đang dở" lists opened lessons newest first, without Học tiếp', () {
    final p = plan([
      rec(id(a, 'a1'), LessonStatus.opened, openedMin: 1),
      rec(id(c, 'c1'), LessonStatus.opened, openedMin: 3),
      rec(id(a, 'a-side'), LessonStatus.opened, openedMin: 2),
      rec(id(b, 'b2'), LessonStatus.read),
    ]);
    expect(p.next!.id, id(a, 'a1'));
    expect(p.inProgress, [id(c, 'c1'), id(a, 'a-side')]);
  });

  test('quiz waiting = main-path read lessons, newest first, max 5', () {
    final big = buildContent([
      BModule('t', 'm', 0, [for (var i = 0; i < 7; i++) BLesson('l$i')]),
    ]);
    final rows = {
      for (var i = 0; i < 7; i++)
        't.l1.l$i': rec('t.l1.l$i', LessonStatus.read, readMin: i),
    };
    final p = LearningPlan.compute(big, rows, const {});
    expect(p.pendingQuiz.map((e) => e.id), [
      't.l1.l6',
      't.l1.l5',
      't.l1.l4',
      't.l1.l3',
      't.l1.l2',
    ]);
    expect(p.next, isNull);
  });

  test('counting to the gate: only passed lessons of the current stage', () {
    final p = plan([
      rec(id(a, 'a1'), LessonStatus.passed),
      rec(id(a, 'a2'), LessonStatus.read),
      rec(id(a, 'a-side'), LessonStatus.passed),
      rec(id(c, 'c1'), LessonStatus.passed),
    ]);
    expect(p.remainingToGate, 4);
  });

  test('gate ready when every main lesson of the stage passed', () {
    final c0 = buildContent([a]);
    final rows = {
      for (final s in ['a1', 'a2', 'a3'])
        id(a, s): rec(id(a, s), LessonStatus.passed),
    };
    final p = LearningPlan.compute(c0, rows, const {});
    expect(p.remainingToGate, 0);
    expect(p.gateReady, isTrue);
    expect(p.next, isNull);
  });

  test('passing a gate moves the current stage; all gates → finished', () {
    expect(plan([], gates: {0}).currentStage, 1);
    expect(plan([], gates: {0}).remainingToGate, 2);
    final done = plan([], gates: {0, 1});
    expect(done.currentStage, isNull);
    expect(done.finished, isTrue);
    expect(done.gateReady, isFalse);
  });

  test('Bài x/y counts every lesson of the module, side branches too', () {
    final pos = lessonPosition(content, id(a, 'a3'))!;
    expect((pos.index, pos.total), (4, 4));
    final upcoming = lessonPosition(content, id(b, 'b1'))!;
    expect((upcoming.index, upcoming.total), (1, 2));
    expect(lessonPosition(content, 'nope'), isNull);
  });

  test('sample content: Học tiếp is the one lesson with a body', () {
    final sample = sampleContent();
    final p = LearningPlan.compute(sample, const {}, const {});
    final lesson = sample.lessons.values.single;
    expect(p.next!.id, lesson.id);
    final pos = lessonPosition(sample, lesson.id)!;
    final module = sample.module(lesson.moduleKey)!;
    expect(pos.total, module.lessons.length);
    expect(pos.index, module.lessons.indexWhere((r) => r.id == lesson.id) + 1);
  });
}
