// docs/07 §5.3 / §9 "review_scheduler": tier table, 04:00 boundary, second
// wrong the same day, retired, gate questions never enter review, content
// removing a question, session cut and order, term flashcards.
// Local DateTimes keep the 04:00 boundary independent of the machine zone.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/progress/review_scheduler.dart';

void main() {
  test('day starts at 04:00 local', () {
    expect(
      reviewDayStart(DateTime(2026, 11, 5, 3, 59)),
      DateTime(2026, 11, 4, 4),
    );
    expect(reviewDayStart(DateTime(2026, 11, 5, 4)), DateTime(2026, 11, 5, 4));
    expect(
      reviewDayStart(DateTime(2026, 11, 5, 23, 59)),
      DateTime(2026, 11, 5, 4),
    );
  });

  test('new wrong answer → tier 0, due now + 1 day', () {
    expect(
      ReviewScheduler.onWrong(null, DateTime(2026, 11, 5, 10)),
      ReviewState(tier: 0, dueAt: DateTime(2026, 11, 6, 10), lastResult: 0),
    );
  });

  test('existing item at a higher tier → tier 0, due tomorrow', () {
    final before = ReviewState(
      tier: 2,
      dueAt: DateTime(2026, 11, 9),
      lastResult: 1,
    );
    expect(
      ReviewScheduler.onWrong(before, DateTime(2026, 11, 5, 10)),
      ReviewState(tier: 0, dueAt: DateTime(2026, 11, 6, 10), lastResult: 0),
    );
  });

  test('second wrong the same review day keeps due_at', () {
    final first = ReviewScheduler.onWrong(null, DateTime(2026, 11, 5, 9));
    expect(ReviewScheduler.onWrong(first, DateTime(2026, 11, 5, 22)), first);
    // 02:00 next morning is still the same review day.
    expect(ReviewScheduler.onWrong(first, DateTime(2026, 11, 6, 2)), first);
  });

  test('wrong again on a later day moves due_at', () {
    final first = ReviewScheduler.onWrong(null, DateTime(2026, 11, 5, 9));
    final later = ReviewScheduler.onWrong(first, DateTime(2026, 11, 7, 9));
    expect(later.dueAt, DateTime(2026, 11, 8, 9));
  });

  test('a retired item answered wrong comes back at tier 0', () {
    final retired = ReviewState(
      tier: 4,
      dueAt: DateTime(2026, 10, 1),
      lastResult: 1,
      retired: true,
    );
    final next = ReviewScheduler.onWrong(retired, DateTime(2026, 11, 5, 9));
    expect(next.tier, 0);
    expect(next.retired, isFalse);
  });

  group('tier table', () {
    final now = DateTime(2026, 11, 5, 10);

    test('right in review: 0→1 (3 d), 1→2 (7 d), 2→3 (21 d), 3→4 retired', () {
      var s = ReviewState(tier: 0, dueAt: now, lastResult: 0);
      final expected = [(1, 3), (2, 7), (3, 21)];
      for (final (tier, days) in expected) {
        s = ReviewScheduler.onRightInReview(s, now);
        expect(s.tier, tier);
        expect(s.dueAt, now.add(Duration(days: days)));
        expect(s.lastResult, 1);
        expect(s.retired, isFalse);
        expect(TierChange(null, s).days, days);
      }
      s = ReviewScheduler.onRightInReview(s, now);
      expect(s.tier, 4);
      expect(s.retired, isTrue);
    });

    test('intervals per tier', () {
      expect(reviewIntervalDays, [1, 3, 7, 21]);
    });

    test('right outside a review session changes nothing', () {
      final s = ReviewState(tier: 0, dueAt: now, lastResult: 0);
      final t2 = ReviewState(tier: 2, dueAt: now, lastResult: 1);
      for (final mode in [ReviewAnswerMode.lesson, ReviewAnswerMode.module]) {
        expect(ReviewScheduler.next(null, correct: true, mode: mode, now: now), isNull);
        expect(ReviewScheduler.next(s, correct: true, mode: mode, now: now), isNull);
        expect(ReviewScheduler.next(t2, correct: true, mode: mode, now: now), isNull);
      }
    });

    test('gate questions never enter review', () {
      for (final correct in [true, false]) {
        expect(
          ReviewScheduler.next(
            null,
            correct: correct,
            mode: ReviewAnswerMode.gate,
            now: now,
          ),
          isNull,
        );
      }
    });

    test('wrong in review resets to tier 0, due tomorrow', () {
      final s = ReviewState(tier: 3, dueAt: now, lastResult: 1);
      final n = ReviewScheduler.next(
        s,
        correct: false,
        mode: ReviewAnswerMode.review,
        now: now,
      )!;
      expect(n.tier, 0);
      expect(n.dueAt, now.add(const Duration(days: 1)));
    });

    test('second wrong the same day via next() → no change', () {
      final first = ReviewScheduler.onWrong(null, now);
      expect(
        ReviewScheduler.next(
          first,
          correct: false,
          mode: ReviewAnswerMode.review,
          now: now.add(const Duration(hours: 3)),
        ),
        isNull,
      );
    });
  });

  group('due (04:00 boundary)', () {
    test('due = due_at ≤ today 04:00 + 24 h', () {
      final now = DateTime(2026, 11, 6, 5);
      expect(isReviewDue(DateTime(2026, 11, 6, 23), now), isTrue);
      expect(isReviewDue(DateTime(2026, 11, 7, 4), now), isTrue);
      expect(isReviewDue(DateTime(2026, 11, 7, 4, 1), now), isFalse);
      // 03:00 still belongs to the previous review day.
      expect(isReviewDue(DateTime(2026, 11, 6, 10), DateTime(2026, 11, 6, 3)), isFalse);
    });

    test('a wrong answer at 23:59 is due the next morning, not at 00:01', () {
      final wrong = ReviewScheduler.onWrong(null, DateTime(2026, 11, 5, 23, 59));
      expect(isReviewDue(wrong.dueAt, DateTime(2026, 11, 6, 0, 1)), isFalse);
      expect(isReviewDue(wrong.dueAt, DateTime(2026, 11, 6, 4)), isTrue);
    });

    test('day key and day distance follow the 04:00 day', () {
      expect(reviewDayKey(DateTime(2026, 11, 6, 3, 59)), '2026-11-05');
      expect(reviewDayKey(DateTime(2026, 11, 6, 4)), '2026-11-06');
      expect(
        reviewDaysBetween(DateTime(2026, 11, 5, 10), DateTime(2026, 11, 8, 3)),
        2,
      );
    });
  });

  group('sessions', () {
    final now = DateTime(2026, 11, 10, 9);
    ReviewItemRecord item(String id, DateTime due, {bool retired = false}) =>
        ReviewItemRecord(
          itemId: id,
          isTerm: id.startsWith(termItemPrefix),
          sourceLesson: 'l',
          state: ReviewState(tier: 0, dueAt: due, lastResult: 0, retired: retired),
        );

    test('due, not retired, still in content; oldest first; cut at max', () {
      final items = [
        for (var i = 0; i < 30; i++) item('q$i', now.subtract(Duration(hours: i))),
        item('retired', now.subtract(const Duration(days: 9)), retired: true),
        item('gone', now.subtract(const Duration(days: 9))),
        item('later', now.add(const Duration(days: 2))),
      ];
      bool exists(String id) => id != 'gone';
      final due = ReviewScheduler.due(items, now, exists);
      expect(due.length, 30);
      expect(due.first.itemId, 'q29');
      final plan = ReviewScheduler.plan(
        items,
        now: now,
        max: 20,
        exists: exists,
        random: Random(1),
      );
      expect(plan.itemIds.length, 20);
      expect(plan.dueTotal, 30);
      expect(plan.remaining, 10);
      // The 20 longest overdue, in shuffled order.
      expect(plan.itemIds.toSet(), {for (var i = 10; i < 30; i++) 'q$i'});
    });

    test('same seed → same order (reproducible)', () {
      final items = [for (var i = 0; i < 8; i++) item('q$i', now)];
      List<String> run() => ReviewScheduler.plan(
        items,
        now: now,
        max: 20,
        exists: (_) => true,
        random: Random(7),
      ).itemIds;
      expect(run(), run());
    });

    test('content removed a question → it retires', () {
      final items = [
        item('keep', now),
        item('gone', now),
        item('old', now, retired: true),
      ];
      expect(ReviewScheduler.missing(items, (id) => id == 'keep'), ['gone']);
    });

    test('upcoming counts per review day', () {
      final items = [
        item('a', now.add(const Duration(days: 1))),
        item('b', now.add(const Duration(days: 1, hours: 2))),
        item('c', now.add(const Duration(days: 3))),
        item('d', now),
        item('e', now.add(const Duration(days: 3)), retired: true),
      ];
      expect(ReviewScheduler.upcoming(items, now, (_) => true), [(1, 2), (3, 1)]);
    });
  });

  group('terms', () {
    final now = DateTime(2026, 11, 5, 10);

    test('"Thêm vào ôn": tier 0 due tomorrow; active item untouched', () {
      final s = ReviewScheduler.addTerm(null, now)!;
      expect(s.tier, 0);
      expect(s.dueAt, now.add(const Duration(days: 1)));
      expect(ReviewScheduler.addTerm(s, now), isNull);
      final retired = ReviewState(tier: 4, dueAt: now, lastResult: 1, retired: true);
      expect(ReviewScheduler.addTerm(retired, now)!.retired, isFalse);
    });

    test('item ids', () {
      expect(termItemId('status-code'), 'term:status-code');
      expect(termSlugOf('term:status-code'), 'status-code');
      expect(termSlugOf('foundation.l1.x.q1'), isNull);
    });

    GlossaryEntry g(String term, String lesson) => GlossaryEntry(
      term: term,
      en: term,
      viKeep: true,
      vi: term,
      shortVi: 'vi $term',
      shortEn: 'en $term',
      introducedIn: lesson,
    );

    final glossary = [
      g('a', 'net.l1.x'),
      g('b', 'net.l1.x'),
      g('c', 'net.l1.y'),
      g('d', 'net.l1.y'),
      g('e', 'net.l1.y'),
      g('z', 'git.l1.z'),
    ];
    String? trackOf(GlossaryEntry e) => e.introducedIn.split('.').first;

    Question card(GlossaryEntry e, int seed, [List<GlossaryEntry>? from]) =>
        ReviewScheduler.termCard(
          e,
          glossary: from ?? glossary,
          trackOf: trackOf,
          question: I18n(vi: '${e.term} nghĩa là gì?', en: 'What does ${e.term} mean?'),
          otherExplanation: (o) => I18n(vi: 'của ${o.term}', en: 'of ${o.term}'),
          random: Random(seed),
        );

    test('4 shorts: the right one + 3 from the same track', () {
      final q = card(glossary[0], 3);
      expect(q.id, 'term:a');
      expect(q.type, QuestionType.single);
      expect(q.options.length, 4);
      final texts = [for (final o in q.options) o.text.vi];
      expect(texts, contains('vi a'));
      expect(texts, isNot(contains('vi z')));
      final right = q.options.firstWhere((o) => o.id == q.answer.single);
      expect(right.text, const I18n(vi: 'vi a', en: 'en a'));
      expect(q.explanationVi['correct'], 'a: vi a');
      for (final o in q.options.where((o) => o.id != q.answer.single)) {
        expect(q.explanationVi[o.id], startsWith('của '));
      }
    });

    test('small track is topped up from the whole glossary', () {
      final q = card(glossary[0], 1, [glossary[0], glossary[1], glossary[5]]);
      expect(q.options.length, 3);
      expect(
        [for (final o in q.options) o.text.vi],
        containsAll(['vi a', 'vi b', 'vi z']),
      );
    });

    test('same seed → same options and answer', () {
      final a = card(glossary[2], 42);
      final b = card(glossary[2], 42);
      expect(
        [for (final o in a.options) o.text.vi],
        [for (final o in b.options) o.text.vi],
      );
      expect(a.answer, b.answer);
      expect(stableSeed('status-code', 3), stableSeed('status-code', 3));
      expect(stableSeed('status-code', 3), isNot(stableSeed('status-code', 4)));
    });
  });
}
