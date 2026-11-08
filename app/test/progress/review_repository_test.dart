// review_repository.dart over an in-memory database and a fixed clock
// (DECISIONS.md E7): "Thêm vào ôn", review answers promote / reset and count
// times_seen, sessions resume the same day, content removal retires items,
// `review_max_per_session`, the S7 overview.
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/content_repository.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/quiz_repository.dart';
import 'package:lta_app/progress/review_repository.dart';
import 'package:lta_app/progress/review_scheduler.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FixedClock clock;
  late ReviewRepository repo;
  late Content content;
  late ReviewCatalog catalog;

  setUp(() {
    db = memoryDb();
    clock = FixedClock(testEpoch);
    repo = ReviewRepository(db, clock);
    content = sampleContent();
    catalog = ReviewCatalog(content);
  });
  tearDown(() => db.close());

  Question q(int i) => content.quizzes.values.single.questions[i];

  Future<void> wrongInLesson(String id) async {
    final quiz = QuizRepository(db, clock);
    final a = await quiz.startOrResume(QuizKind.lesson, 'l', [id]);
    await quiz.recordAnswer(
      attemptId: a.id,
      kind: QuizKind.lesson,
      questionId: id,
      answer: const ['x'],
      correct: false,
      sourceLesson: content.lessons.keys.single,
    );
  }

  test('catalog: questions and glossary terms exist, others do not', () {
    expect(catalog.exists(q(0).id), isTrue);
    expect(catalog.exists('term:header'), isTrue);
    expect(catalog.exists('term:nope'), isFalse);
    expect(catalog.exists('nope.q1'), isFalse);
    expect(catalog.sourceLesson(q(0).id), content.lessons.keys.single);
    final card = catalog.question('term:header', 1)!;
    expect(card.options.length, 4);
    expect(card.question.vi, 'header nghĩa là gì?');
    expect(card.question.en, 'What does header mean?');
    // Stable per (session, term).
    expect(catalog.question('term:header', 1)!.answer, card.answer);
  });

  test('"Thêm vào ôn" creates term:<slug> tier 0 due tomorrow, once', () async {
    final header = content.glossaryEntry('header')!;
    expect(await repo.addTerm(header), isTrue);
    expect(await repo.addTerm(header), isFalse);
    final item = (await repo.item('term:header'))!;
    expect(item.isTerm, isTrue);
    expect(item.state.tier, 0);
    expect(item.state.dueAt, testEpoch.add(const Duration(days: 1)));
    expect(item.sourceLesson, header.introducedIn);
    final row = (await db.select(db.reviewItem).get()).single;
    expect(row.kind, 'term');
  });

  test('review answers: right promotes, wrong resets; times_seen counts', () async {
    await wrongInLesson(q(0).id);
    clock.advance(const Duration(days: 1));
    final id = (await repo.startSession(catalog, Random(1)))!;
    var ch = await repo.recordAnswer(
      attemptId: id,
      itemId: q(0).id,
      answer: const ['a'],
      correct: true,
    );
    expect((ch.fromTier, ch.toTier, ch.days, ch.promoted), (0, 1, 3, true));
    var item = (await repo.item(q(0).id))!;
    expect(item.timesSeen, 1);
    expect(item.state.dueAt, clock.now().add(const Duration(days: 3)));

    ch = await repo.recordAnswer(
      attemptId: id,
      itemId: q(0).id,
      answer: const ['b'],
      correct: false,
    );
    expect((ch.toTier, ch.promoted), (0, false));
    item = (await repo.item(q(0).id))!;
    expect(item.timesSeen, 2);
    expect(item.state.dueAt, clock.now().add(const Duration(days: 1)));
  });

  test('tier 3 right → retired', () async {
    await db.into(db.reviewItem).insert(
      ReviewItemCompanion.insert(
        itemId: Value(q(1).id),
        kind: 'question',
        tier: const Value(3),
        dueAt: isoUtc(testEpoch),
      ),
    );
    final id = (await repo.startSession(catalog, Random(1)))!;
    final ch = await repo.recordAnswer(
      attemptId: id,
      itemId: q(1).id,
      answer: const ['a'],
      correct: true,
    );
    expect(ch.retired, isTrue);
    expect((await repo.item(q(1).id))!.state.retired, isTrue);
  });

  test('session: nothing due → null; same day resumes; finished → new', () async {
    expect(await repo.startSession(catalog, Random(1)), isNull);
    await wrongInLesson(q(0).id);
    await wrongInLesson(q(1).id);
    // Not due the same day.
    expect(await repo.startSession(catalog, Random(1)), isNull);
    clock.advance(const Duration(days: 1));
    final a = (await repo.startSession(catalog, Random(1)))!;
    expect(await repo.startSession(catalog, Random(2)), a);
    final attempt = (await QuizRepository(db, clock).attempt(a))!;
    expect(attempt.kind, QuizKind.review);
    expect(attempt.refId, reviewDayKey(clock.now()));
    expect(attempt.questionIds.toSet(), {q(0).id, q(1).id});
    await repo.finishSession(a, score: 2, total: 2);
    // Both still due (nothing answered) → a fresh session.
    final b = await repo.startSession(catalog, Random(1));
    expect(b, isNot(a));
    final events = await db.select(db.event).get();
    expect(events.where((e) => e.kind == 'review_finished'), hasLength(1));
  });

  test('review_max_per_session cuts the session', () async {
    for (var i = 0; i < 4; i++) {
      await wrongInLesson(q(i).id);
    }
    await db.into(db.settings).insert(
      SettingsCompanion.insert(key: const Value(reviewMaxSettingKey), value: '3'),
    );
    expect(await repo.maxPerSession(), 3);
    clock.advance(const Duration(days: 1));
    final a = (await repo.startSession(catalog, Random(1)))!;
    expect((await QuizRepository(db, clock).attempt(a))!.questionIds, hasLength(3));
  });

  test('content update: items whose question is gone retire, rows stay', () async {
    await wrongInLesson(q(0).id);
    await wrongInLesson('removed.lesson.q9');
    expect(await repo.retireMissing(catalog.exists), 1);
    final rows = {for (final r in await db.select(db.reviewItem).get()) r.itemId: r};
    expect(rows['removed.lesson.q9']!.retired, 1);
    expect(rows[q(0).id]!.retired, 0);
    expect(await repo.retireMissing(catalog.exists), 0);
  });

  test('overview: due, lessons, minutes, upcoming; refreshes with the day', () async {
    final container = ProviderContainer(
      overrides: [...contentOverrides(), ...progressOverrides(db, clock: clock)],
    );
    addTearDown(container.dispose);
    await wrongInLesson(q(0).id);
    await wrongInLesson(q(1).id);
    await repo.addTerm(content.glossaryEntry('header')!);
    container.listen(reviewOverviewProvider, (_, _) {});
    await container.read(reviewItemsProvider.future);
    await container.read(reviewMaxProvider.future);
    await container.read(contentProvider.future);
    var o = container.read(reviewOverviewProvider).requireValue;
    expect(o.dueTotal, 0);
    expect(o.upcoming, [(1, 3)]);

    clock.advance(const Duration(days: 1));
    container.read(reviewDayProvider.notifier).refresh();
    o = container.read(reviewOverviewProvider).requireValue;
    expect(o.dueTotal, 3);
    expect(o.sessionSize, 3);
    expect(o.lessons, 1); // "header" is taught in the sample lesson itself
    expect(o.minutes, 1);
    expect(o.upcoming, isEmpty);
  });
}
