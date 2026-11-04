// Review tiers — docs/07 §5.3. Pure functions over [ReviewState]: wrong
// answers create / reset items, right answers in a review session promote
// them, due lists honour the 04:00 day boundary, sessions are cut at
// `review_max_per_session`, items whose question left the content retire, and
// term flashcards become 4-option questions. Time and randomness are passed
// in (DECISIONS.md E7); the database side lives in review_repository.dart.
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/models/models.dart';

/// Days until the next review per tier (`tier 4 → retired`).
const List<int> reviewIntervalDays = [1, 3, 7, 21];

/// The tier at which an item retires.
const int reviewRetiredTier = 4;

/// Hour of the local day boundary ("Ngày" = mốc 04:00 giờ địa phương).
const int reviewDayStartHour = 4;

/// `settings.review_max_per_session` default (docs/07 §4).
const int reviewDefaultMaxPerSession = 20;

/// Rough time per review item, for "~4 phút" / "Ôn 5 phút" (12 items ≈ 4 min
/// in the docs/05 S7 wireframe).
const int reviewSecondsPerItem = 20;

/// `review_item.item_id` prefix of a term flashcard.
const String termItemPrefix = 'term:';

String termItemId(String slug) => '$termItemPrefix$slug';

/// Slug of a term item id, or `null` for a question id.
String? termSlugOf(String itemId) => itemId.startsWith(termItemPrefix)
    ? itemId.substring(termItemPrefix.length)
    : null;

/// Start of the review day containing [t]: the latest local 04:00 ≤ [t].
DateTime reviewDayStart(DateTime t) {
  final local = t.toLocal();
  var start = DateTime(local.year, local.month, local.day, reviewDayStartHour);
  if (local.isBefore(start)) {
    start = DateTime(local.year, local.month, local.day - 1, reviewDayStartHour);
  }
  return start;
}

/// Whole review days from the day of [from] to the day of [to] (calendar
/// arithmetic, so a DST shift never makes a day 23 or 25 hours).
int reviewDaysBetween(DateTime from, DateTime to) {
  final a = reviewDayStart(from);
  final b = reviewDayStart(to);
  return DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
}

/// `yyyy-MM-dd` of the review day of [t] (`quiz_attempt.ref_id` of a review
/// session).
String reviewDayKey(DateTime t) {
  final d = reviewDayStart(t);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// docs/07 §5.3: due = `due_at ≤ mốc 04:00 hôm nay + 24 giờ`.
bool isReviewDue(DateTime dueAt, DateTime now) {
  final end = reviewDayStart(now).add(const Duration(hours: 24));
  return !dueAt.isAfter(end);
}

/// The fields of a `review_item` row the scheduler decides.
@immutable
class ReviewState {
  const ReviewState({
    required this.tier,
    required this.dueAt,
    required this.lastResult,
    this.retired = false,
  });

  final int tier;
  final DateTime dueAt;

  /// 0 = wrong, 1 = right; `null` before the first answer.
  final int? lastResult;
  final bool retired;

  @override
  bool operator ==(Object other) =>
      other is ReviewState &&
      other.tier == tier &&
      other.dueAt.isAtSameMomentAs(dueAt) &&
      other.lastResult == lastResult &&
      other.retired == retired;

  @override
  int get hashCode => Object.hash(tier, dueAt.millisecondsSinceEpoch, lastResult, retired);

  @override
  String toString() =>
      'ReviewState(tier: $tier, dueAt: $dueAt, last: $lastResult, retired: $retired)';
}

/// Where an answer was given (`quiz_attempt.kind`).
enum ReviewAnswerMode { lesson, module, review, gate }

/// One `review_item` row.
@immutable
class ReviewItemRecord {
  const ReviewItemRecord({
    required this.itemId,
    required this.isTerm,
    required this.sourceLesson,
    required this.state,
    this.timesSeen = 0,
  });

  final String itemId;
  final bool isTerm;

  /// Lesson of the question / `introduced_in` of the term.
  final String? sourceLesson;
  final ReviewState state;
  final int timesSeen;
}

/// Tier move shown after an answer in a review session (docs/05 S4).
@immutable
class TierChange {
  const TierChange(this.before, this.after);

  final ReviewState? before;
  final ReviewState after;

  int get fromTier => before?.tier ?? 0;
  int get toTier => after.tier;
  bool get promoted => after.lastResult == 1;
  bool get retired => after.retired;

  /// Days from the answer until the item is due again.
  int get days => reviewIntervalDays[toTier.clamp(0, reviewIntervalDays.length - 1)];
}

/// The items of one review session (docs/07 §5.3 "Phiên ôn").
@immutable
class ReviewSessionPlan {
  const ReviewSessionPlan({required this.itemIds, required this.dueTotal});

  /// In session order.
  final List<String> itemIds;

  /// Every due item (the session is cut at `review_max_per_session`).
  final int dueTotal;

  /// "còn 22 câu, ôn tiếp sau".
  int get remaining => dueTotal - itemIds.length;
}

abstract final class ReviewScheduler {
  /// A wrong answer in a lesson/module/review quiz (docs/07 §5.3):
  /// new item → tier 0, due now + 1 day; existing → tier 0, due now + 1 day;
  /// already wrong earlier the same review day → unchanged (still tomorrow).
  static ReviewState onWrong(ReviewState? existing, DateTime now) {
    final due = now.add(Duration(days: reviewIntervalDays[0]));
    if (existing == null) return ReviewState(tier: 0, dueAt: due, lastResult: 0);
    final wrongToday =
        existing.tier == 0 &&
        existing.lastResult == 0 &&
        reviewDayStart(
          existing.dueAt.subtract(Duration(days: reviewIntervalDays[0])),
        ).isAtSameMomentAs(reviewDayStart(now));
    if (wrongToday && !existing.retired) return existing;
    return ReviewState(tier: 0, dueAt: due, lastResult: 0);
  }

  /// A right answer in a review session: `tier += 1`, due now + interval of
  /// the new tier; reaching tier 4 retires the item.
  static ReviewState onRightInReview(ReviewState existing, DateTime now) {
    final tier = existing.tier + 1;
    if (tier >= reviewRetiredTier) {
      return ReviewState(
        tier: reviewRetiredTier,
        dueAt: existing.dueAt,
        lastResult: 1,
        retired: true,
      );
    }
    return ReviewState(
      tier: tier,
      dueAt: now.add(Duration(days: reviewIntervalDays[tier])),
      lastResult: 1,
    );
  }

  /// The item state after an answer, or `null` when no item is created or
  /// changed: gate questions never enter review; a right answer outside a
  /// review session leaves an item (and its absence) alone.
  static ReviewState? next(
    ReviewState? existing, {
    required bool correct,
    required ReviewAnswerMode mode,
    required DateTime now,
  }) {
    if (mode == ReviewAnswerMode.gate) return null;
    if (!correct) {
      final s = onWrong(existing, now);
      return s == existing ? null : s;
    }
    if (mode != ReviewAnswerMode.review || existing == null) return null;
    return onRightInReview(existing, now);
  }

  /// "Thêm vào ôn" from TermTooltip: tier 0, due tomorrow. An active item is
  /// left alone (`null`); a retired one starts over.
  static ReviewState? addTerm(ReviewState? existing, DateTime now) {
    if (existing != null && !existing.retired) return null;
    return ReviewState(
      tier: 0,
      dueAt: now.add(Duration(days: reviewIntervalDays[0])),
      lastResult: null,
    );
  }

  /// Active (not retired) items whose question / term still exists, due now.
  static List<ReviewItemRecord> due(
    Iterable<ReviewItemRecord> items,
    DateTime now,
    bool Function(String itemId) exists,
  ) {
    final list = [
      for (final i in items)
        if (!i.state.retired && exists(i.itemId) && isReviewDue(i.state.dueAt, now)) i,
    ]..sort(_byDue);
    return list;
  }

  static int _byDue(ReviewItemRecord a, ReviewItemRecord b) {
    final c = a.state.dueAt.compareTo(b.state.dueAt);
    return c != 0 ? c : a.itemId.compareTo(b.itemId);
  }

  /// Session: due items, longest overdue first, cut at [max], then mixed
  /// (questions and term cards shuffled together) with [random].
  static ReviewSessionPlan plan(
    Iterable<ReviewItemRecord> items, {
    required DateTime now,
    required int max,
    required bool Function(String itemId) exists,
    required Random random,
  }) {
    final dueItems = due(items, now, exists);
    final ids = [for (final i in dueItems.take(max)) i.itemId]..shuffle(random);
    return ReviewSessionPlan(itemIds: List.unmodifiable(ids), dueTotal: dueItems.length);
  }

  /// Active items whose question or term is no longer in the content
  /// (content update → `retired = 1`).
  static List<String> missing(
    Iterable<ReviewItemRecord> items,
    bool Function(String itemId) exists,
  ) => [
    for (final i in items)
      if (!i.state.retired && !exists(i.itemId)) i.itemId,
  ];

  /// Active, not-due items per review day ahead (1 = tomorrow), ascending.
  static List<(int days, int count)> upcoming(
    Iterable<ReviewItemRecord> items,
    DateTime now,
    bool Function(String itemId) exists,
  ) {
    final counts = <int, int>{};
    for (final i in items) {
      if (i.state.retired || !exists(i.itemId) || isReviewDue(i.state.dueAt, now)) {
        continue;
      }
      final d = reviewDaysBetween(now, i.state.dueAt);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final days = counts.keys.toList()..sort();
    return [for (final d in days) (d, counts[d]!)];
  }

  /// Term flashcard as a `single` question: "what does [entry] mean?" with
  /// 4 `short` texts — the right one plus 3 from glossary terms of the same
  /// track (topped up from the whole glossary when the track has fewer).
  /// [question] holds the prompt per language (UI copy, from the ARB).
  static Question termCard(
    GlossaryEntry entry, {
    required List<GlossaryEntry> glossary,
    required String? Function(GlossaryEntry e) trackOf,
    required I18n question,
    required I18n Function(GlossaryEntry other) otherExplanation,
    required Random random,
  }) {
    final track = trackOf(entry);
    final seen = {entry.shortVi, entry.shortEn};
    bool fresh(GlossaryEntry g) =>
        g.term != entry.term && !seen.contains(g.shortVi) && !seen.contains(g.shortEn);
    final same = [
      for (final g in glossary)
        if (fresh(g) && trackOf(g) == track) g,
    ]..shuffle(random);
    final picked = <GlossaryEntry>[];
    void take(Iterable<GlossaryEntry> from) {
      for (final g in from) {
        if (picked.length == 3) return;
        if (!fresh(g)) continue;
        picked.add(g);
        seen
          ..add(g.shortVi)
          ..add(g.shortEn);
      }
    }

    take(same);
    if (picked.length < 3) {
      take([
        for (final g in glossary)
          if (trackOf(g) != track) g,
      ]..shuffle(random));
    }
    final choices = [entry, ...picked]..shuffle(random);
    final ids = [for (var i = 0; i < choices.length; i++) String.fromCharCode(0x61 + i)];
    final answer = ids[choices.indexOf(entry)];
    return Question(
      id: termItemId(entry.term),
      type: QuestionType.single,
      bloom: Bloom.remember,
      difficulty: 1,
      skills: const [],
      track: track,
      module: null,
      sectionRef: null,
      context: null,
      question: question,
      options: [
        for (final (i, g) in choices.indexed)
          QuestionOption(
            id: ids[i],
            text: I18n(vi: g.shortVi, en: g.shortEn),
            misconception: null,
            polarity: null,
          ),
      ],
      answer: [answer],
      answerRegex: null,
      explanationVi: {
        'correct': '${entry.name(ContentLang.vi)}: ${entry.shortVi}',
        for (final (i, g) in choices.indexed)
          if (g != entry) ids[i]: otherExplanation(g).vi,
      },
      explanationEn: {
        'correct': '${entry.name(ContentLang.en)}: ${entry.shortEn}',
        for (final (i, g) in choices.indexed)
          if (g != entry) ids[i]: otherExplanation(g).en,
      },
    );
  }
}

/// Stable 31-bit seed from a string (FNV-1a), so a term card keeps its
/// option order across rebuilds and resumes of the same session.
int stableSeed(String s, [int salt = 0]) {
  var h = 0x811c9dc5 ^ salt;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}
