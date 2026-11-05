// exam_repository (docs/07 §4, §5.4, §5.5): gate attempts seeded by their
// id, resume within 24 h, scoring into stage_progress, flags, module quiz
// "Module ✓", the S1 "Tiếp tục quiz" stream; and export/import/reset
// (docs/07 §4 "Xuất tiến độ").
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/exam_repository.dart';
import 'package:lta_app/progress/export_import.dart';
import 'package:lta_app/progress/progress_repository.dart';
import 'package:lta_app/progress/quiz_repository.dart';
import 'package:lta_app/progress/settings_repository.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late QuizRepository quiz;
  late ExamRepository exam;
  final content = contentWithGate();
  final gate = content.gates['gate0']!;

  setUp(() {
    db = memoryDb();
    clock = FixedClock(testEpoch);
    quiz = QuizRepository(db, clock);
    exam = ExamRepository(db, clock, quiz, Random.new);
  });
  tearDown(() => db.close());

  Future<void> answerAll(QuizAttemptRecord a, {required int correct}) async {
    final byId = {for (final q in gate.questions) q.id: q};
    for (final (i, id) in a.questionIds.indexed) {
      final ok = i < correct;
      await quiz.recordAnswer(
        attemptId: a.id,
        kind: QuizKind.gate,
        questionId: id,
        answer: ok ? byId[id]!.answer : ['a'],
        correct: ok,
        sourceLesson: null,
      );
    }
  }

  group('gate', () {
    test('draw is seeded by the attempt id and stored', () async {
      final a = await exam.startGate(content, gate);
      expect(a.questionIds, hasLength(35));
      final stored = await quiz.attempt(a.id);
      expect(stored!.questionIds, a.questionIds);
    });

    test('a paused exam resumes within 24 h, a stale one is closed', () async {
      final a = await exam.startGate(content, gate);
      await quiz.recordAnswer(
        attemptId: a.id,
        kind: QuizKind.gate,
        questionId: a.questionIds.first,
        answer: const ['b'],
        correct: true,
        sourceLesson: null,
      );
      clock.advance(const Duration(hours: 23));
      expect((await exam.pausedGate(gate))?.id, a.id);
      expect((await exam.startGate(content, gate)).id, a.id);
      clock.advance(const Duration(hours: 2));
      expect(await exam.pausedGate(gate), isNull);
      final b = await exam.startGate(content, gate);
      expect(b.id, isNot(a.id));
      expect((await quiz.attempt(a.id))!.abandoned, isTrue);
      final unused = {
        for (final q in gate.questions) q.id,
      }.difference(a.questionIds.toSet());
      expect(
        b.questionIds.toSet().containsAll(unused),
        isTrue,
        reason: '50 − 35 < 35: the last draw is only avoided first',
      );
    });

    test('gate answers never enter review', () async {
      final a = await exam.startGate(content, gate);
      await answerAll(a, correct: 0);
      expect(await db.select(db.reviewItem).get(), isEmpty);
    });

    test('finish: < 75% counts an attempt; ≥ 75% passes the stage', () async {
      final a = await exam.startGate(content, gate);
      await answerAll(a, correct: 20);
      final r1 = await exam.finishGate(a.id, 0);
      expect((r1.score, r1.total, r1.passed), (20, 35, false));
      var row = await db.select(db.stageProgress).getSingle();
      expect(row.attempts, 1);
      expect(row.gatePassedAt, isNull);
      expect(row.bestGateScore, closeTo(20 / 35, 1e-9));

      final b = await exam.startGate(content, gate);
      await answerAll(b, correct: 27);
      final r2 = await exam.finishGate(b.id, 0);
      expect(r2.passed, isTrue);
      row = await db.select(db.stageProgress).getSingle();
      expect(row.attempts, 2);
      expect(row.gatePassedAt, isNotNull);
      final events = await db.select(db.event).get();
      expect(events.where((e) => e.kind == 'gate_finished'), hasLength(2));
      final history = await exam.watchGateHistory('gate0').first;
      expect([for (final h in history) h.score], [27, 20]);
    });

    test('flags survive an answer and an unanswered flag stays empty', () async {
      final a = await exam.startGate(content, gate);
      final [q1, q2, ...] = a.questionIds;
      await exam.setFlag(a.id, q1, true);
      await exam.setFlag(a.id, q2, true);
      await quiz.recordAnswer(
        attemptId: a.id,
        kind: QuizKind.gate,
        questionId: q1,
        answer: const ['b'],
        correct: true,
        sourceLesson: null,
      );
      expect(await exam.flagged(a.id), {q1, q2});
      await exam.setFlag(a.id, q2, false);
      expect(await exam.flagged(a.id), {q1});
      expect((await quiz.attempt(a.id))!.answers[q2]!.answer, isEmpty);
    });
  });

  group('module quiz', () {
    final module = content.module('backend/web')!;

    test('draws from every lesson, resumes the open attempt', () async {
      final a = await exam.startModule(content, module);
      expect(a.questionIds, hasLength(15));
      for (final l in module.lessons) {
        expect(a.questionIds.any((id) => id.startsWith('${l.id}.')), isTrue);
      }
      expect((await exam.startModule(content, module)).id, a.id);
    });

    test('≥ 70% → Module ✓, lesson progress untouched', () async {
      final a = await exam.startModule(content, module);
      await quiz.finish(a.id, score: 10, total: 15);
      expect(await exam.watchPassedModules().first, isEmpty);
      final b = await exam.startModule(content, module);
      await quiz.finish(b.id, score: 11, total: 15);
      expect(await exam.watchPassedModules().first, {'backend/web'});
      expect(await db.select(db.lessonProgress).get(), isEmpty);
    });
  });

  test('open quiz: newest unfinished with an answer', () async {
    expect(await exam.watchOpenQuiz().first, isNull);
    final a = await exam.startModule(content, contentWithGate().module('backend/web')!);
    expect(await exam.watchOpenQuiz().first, isNull, reason: 'no answer yet');
    await quiz.recordAnswer(
      attemptId: a.id,
      kind: QuizKind.module,
      questionId: a.questionIds.first,
      answer: const ['b'],
      correct: true,
      sourceLesson: null,
    );
    final open = await exam.watchOpenQuiz().first;
    expect((open!.kind, open.refId, open.answered, open.total), (
      QuizKind.module,
      'backend/web',
      1,
      15,
    ));
    await quiz.finish(a.id, score: 1, total: 15);
    expect(await exam.watchOpenQuiz().first, isNull);
  });

  group('export / import / reset', () {
    late ProgressTransfer transfer;
    setUp(() => transfer = ProgressTransfer(db, clock));

    Future<void> seed() async {
      final progress = ProgressRepository(db, clock);
      await progress.markOpened('backend.l1.a');
      await progress.markRead('backend.l1.a', vocab: ['http']);
      final a = await quiz.startOrResume(QuizKind.lesson, 'backend.l1.a', ['x.q1']);
      await quiz.recordAnswer(
        attemptId: a.id,
        kind: QuizKind.lesson,
        questionId: 'x.q1',
        answer: const ['a'],
        correct: false,
        sourceLesson: 'backend.l1.a',
      );
      final s = SettingsRepository(db);
      await s.set(SettingKeys.contentLang, 'en');
      await s.set(SettingKeys.contentSource, 'remote');
      await s.set(SettingKeys.contentVersion, '9');
    }

    test('round trip restores every exported table', () async {
      await seed();
      final json = await transfer.exportJson();
      final m = jsonDecode(json) as Map<String, Object?>;
      expect(m['schema'], 1);
      expect((m['tables']! as Map).keys, progressTables);
      expect((m['tables']! as Map).containsKey('event'), isFalse);

      await transfer.reset();
      expect(await db.select(db.lessonProgress).get(), isEmpty);
      expect(await db.select(db.quizAnswer).get(), isEmpty);
      final s = SettingsRepository(db);
      expect(await s.get(SettingKeys.contentLang), isNull);
      expect(await s.get(SettingKeys.contentSource), 'remote', reason: 'device');

      await s.set(SettingKeys.contentSource, 'asset');
      await transfer.importJson(json);
      expect((await db.select(db.lessonProgress).getSingle()).status, 'read');
      expect(await db.select(db.quizAnswer).get(), hasLength(1));
      expect(await db.select(db.reviewItem).get(), hasLength(1));
      expect(await db.select(db.vocabSeen).get(), hasLength(1));
      expect(await s.get(SettingKeys.contentLang), 'en');
      expect(
        await s.get(SettingKeys.contentSource),
        'asset',
        reason: 'content cache settings stay this device\'s',
      );
    });

    test('a malformed file changes nothing', () async {
      await seed();
      Future<void> bad(String json) => expectLater(
        transfer.importJson(json),
        throwsA(isA<ProgressImportException>()),
      );
      await bad('not json');
      await bad('{"schema": 2, "tables": {}}');
      await bad(jsonEncode({
        'schema': 1,
        'tables': {
          'lesson_progress': [
            {'lesson_id': 'x', 'status': 'read', 'evil"; DROP TABLE x; --': 1},
          ],
        },
      }));
      expect(await db.select(db.lessonProgress).get(), hasLength(1));
    });
  });
}
