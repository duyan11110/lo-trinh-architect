// quiz_attempt / quiz_answer / review_item writes (docs/07 §4, §5.3).
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/quiz_repository.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late QuizRepository repo;

  setUp(() {
    db = memoryDb();
    repo = QuizRepository(db, FixedClock(testEpoch));
  });
  tearDown(() => db.close());

  const ids = ['l.q1', 'l.q2', 'l.q3'];

  Future<void> answer(
    int attemptId,
    String q,
    List<String> a, {
    required bool correct,
    QuizKind kind = QuizKind.lesson,
  }) => repo.recordAnswer(
    attemptId: attemptId,
    kind: kind,
    questionId: q,
    answer: a,
    correct: correct,
    sourceLesson: kind == QuizKind.gate ? null : 'l',
  );

  test('stores question_ids; an unfinished attempt is resumed', () async {
    final a = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    await answer(a.id, 'l.q1', ['b'], correct: true);
    final again = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    expect(again.id, a.id);
    expect(again.questionIds, ids);
    expect(again.answers['l.q1']!.answer, ['b']);
    expect(again.answers['l.q1']!.correct, isTrue);
    // A different question set (content changed) starts a new attempt.
    final other = await repo.startOrResume(QuizKind.lesson, 'l', ['l.q1']);
    expect(other.id, isNot(a.id));
  });

  test('finish records score + quiz_finished; next start is new', () async {
    final a = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    await repo.finish(a.id, score: 2, total: 3);
    final done = (await repo.attempt(a.id))!;
    expect(done.score, 2);
    expect(done.total, 3);
    expect(done.finished, isTrue);
    expect(done.abandoned, isFalse);
    final ev = (await db.select(db.event).get()).single;
    expect(ev.kind, 'quiz_finished');
    expect(ev.ref, 'l');
    expect(ev.value, closeTo(2 / 3, 1e-9));
    final next = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    expect(next.id, isNot(a.id));
  });

  test('abandon: no score; answers and review items stay', () async {
    final a = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    await answer(a.id, 'l.q2', ['a'], correct: false);
    await repo.abandon(a.id);
    final r = (await repo.attempt(a.id))!;
    expect(r.abandoned, isTrue);
    expect(r.answers, hasLength(1));
    expect(await db.select(db.reviewItem).get(), hasLength(1));
  });

  test('wrong → review item tier 0 due +1 day; right → none', () async {
    final a = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    await answer(a.id, 'l.q1', ['b'], correct: true);
    await answer(a.id, 'l.q2', ['a', 'c'], correct: false);
    final item = (await db.select(db.reviewItem).get()).single;
    expect(item.itemId, 'l.q2');
    expect(item.kind, 'question');
    expect(item.sourceLesson, 'l');
    expect(item.tier, 0);
    expect(item.lastResult, 0);
    expect(item.retired, 0);
    expect(DateTime.parse(item.dueAt), testEpoch.add(const Duration(days: 1)));
    final stored = await db.select(db.quizAnswer).get();
    expect([for (final s in stored) s.answer], ['["b"]', '["a","c"]']);
  });

  test('an existing item is reset to tier 0', () async {
    await db
        .into(db.reviewItem)
        .insert(
          ReviewItemCompanion.insert(
            itemId: const Value('l.q3'),
            kind: 'question',
            sourceLesson: const Value('l'),
            tier: const Value(3),
            dueAt: '2026-12-01T00:00:00.000Z',
            lastResult: const Value(1),
            timesSeen: const Value(4),
          ),
        );
    final a = await repo.startOrResume(QuizKind.lesson, 'l', ids);
    await answer(a.id, 'l.q3', ['d'], correct: false);
    final item = (await db.select(db.reviewItem).get()).single;
    expect(item.tier, 0);
    expect(item.timesSeen, 4);
    expect(DateTime.parse(item.dueAt), testEpoch.add(const Duration(days: 1)));
  });

  test('gate answers never enter review', () async {
    final a = await repo.startOrResume(QuizKind.gate, 'gate0', ['gate0.q1']);
    await answer(a.id, 'gate0.q1', ['a'], correct: false, kind: QuizKind.gate);
    expect(await db.select(db.reviewItem).get(), isEmpty);
    expect(await db.select(db.quizAnswer).get(), hasLength(1));
  });
}
