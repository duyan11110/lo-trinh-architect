// Review persistence and S7 data — docs/07 §4 (`review_item`, `quiz_attempt`
// kind `review`, `vocab_seen`, `settings.review_max_per_session`) and §5.3.
// Decisions come from review_scheduler.dart; this file stores them. Time and
// randomness are injected (DECISIONS.md E7).
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_repository.dart';
import '../content/models/models.dart';
import '../l10n/app_localizations.dart';
import 'clock.dart';
import 'database.dart';
import 'progress_repository.dart';
import 'quiz_repository.dart';
import 'review_scheduler.dart';

/// `settings` key of the session cut (docs/07 §4).
const String reviewMaxSettingKey = 'review_max_per_session';

/// Lesson quiz questions by id, and the term flashcards, of one content load:
/// what a review item can still be.
class ReviewCatalog {
  ReviewCatalog(this.content)
    : _questions = {
        for (final e in content.quizzes.entries)
          for (final q in e.value.questions) q.id: (q, e.value.lesson),
      };

  final Content content;
  final Map<String, (Question, String)> _questions;

  bool exists(String itemId) {
    final slug = termSlugOf(itemId);
    return slug == null
        ? _questions.containsKey(itemId)
        : content.glossaryEntry(slug) != null;
  }

  /// Lesson the item comes from (question's lesson / term's `introduced_in`).
  String? sourceLesson(String itemId) {
    final slug = termSlugOf(itemId);
    if (slug == null) return _questions[itemId]?.$2;
    return content.glossaryEntry(slug)?.introducedIn;
  }

  /// The question shown for [itemId] in session [attemptId]; term cards get
  /// a stable option order per (session, term).
  Question? question(String itemId, int attemptId) {
    final slug = termSlugOf(itemId);
    if (slug == null) return _questions[itemId]?.$1;
    final entry = content.glossaryEntry(slug);
    if (entry == null) return null;
    final vi = lookupL(const Locale('vi'));
    final en = lookupL(const Locale('en'));
    return ReviewScheduler.termCard(
      entry,
      glossary: content.glossary,
      trackOf: content.trackOfTerm,
      question: I18n(
        vi: vi.reviewTermQuestion(entry.name(ContentLang.vi)),
        en: en.reviewTermQuestion(entry.name(ContentLang.en)),
      ),
      otherExplanation: (g) => I18n(
        vi: vi.reviewTermOther(g.name(ContentLang.vi)),
        en: en.reviewTermOther(g.name(ContentLang.en)),
      ),
      random: Random(stableSeed(slug, attemptId)),
    );
  }
}

/// One finished, scored quiz attempt for the S7 "Lịch sử" list.
@immutable
class QuizHistoryEntry {
  const QuizHistoryEntry({
    required this.kind,
    required this.refId,
    required this.finishedAt,
    required this.score,
    required this.total,
  });

  final QuizKind kind;
  final String refId;
  final DateTime finishedAt;
  final int score;
  final int total;
}

/// What S1 (ReviewDueRow) and S7 show.
@immutable
class ReviewOverview {
  const ReviewOverview({
    required this.dueTotal,
    required this.sessionSize,
    required this.lessons,
    required this.upcoming,
  });

  final int dueTotal;

  /// Items the next session takes (≤ `review_max_per_session`).
  final int sessionSize;

  /// Distinct source lessons of the due items.
  final int lessons;
  final List<(int days, int count)> upcoming;

  int get remaining => dueTotal - sessionSize;

  /// "~4 phút".
  int get minutes => (sessionSize * reviewSecondsPerItem / 60).ceil();
}

class ReviewRepository {
  ReviewRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  static ReviewItemRecord _record(ReviewItemData r) => ReviewItemRecord(
    itemId: r.itemId!,
    isTerm: r.kind == 'term',
    sourceLesson: r.sourceLesson,
    state: ReviewState(
      tier: r.tier,
      dueAt: DateTime.parse(r.dueAt),
      lastResult: r.lastResult,
      retired: r.retired != 0,
    ),
    timesSeen: r.timesSeen,
  );

  Stream<List<ReviewItemRecord>> watchItems() => _db
      .select(_db.reviewItem)
      .watch()
      .map((rows) => List.unmodifiable(rows.map(_record)));

  Future<List<ReviewItemRecord>> items() async =>
      List.unmodifiable((await _db.select(_db.reviewItem).get()).map(_record));

  Future<ReviewItemRecord?> item(String itemId) async {
    final row = await (_db.select(
      _db.reviewItem,
    )..where((t) => t.itemId.equals(itemId))).getSingleOrNull();
    return row == null ? null : _record(row);
  }

  /// `settings.review_max_per_session` (default 20).
  Future<int> maxPerSession() async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(reviewMaxSettingKey))).getSingleOrNull();
    final v = int.tryParse(row?.value ?? '');
    return v == null || v < 1 ? reviewDefaultMaxPerSession : v;
  }

  /// "Thêm vào ôn" (docs/07 §5.3): `term:<slug>`, tier 0, due tomorrow.
  /// Returns whether an item was created (or a retired one restarted).
  Future<bool> addTerm(GlossaryEntry entry) => _db.transaction(() async {
    final id = termItemId(entry.term);
    final existing = await item(id);
    final next = ReviewScheduler.addTerm(existing?.state, _clock.now());
    if (next == null) return false;
    await _write(id, 'term', existing?.sourceLesson ?? entry.introducedIn, next,
        existing?.timesSeen ?? 0);
    return true;
  });

  /// Content changed: active items whose question/term is gone retire
  /// (rows kept for export/import).
  Future<int> retireMissing(bool Function(String itemId) exists) =>
      _db.transaction(() async {
        final ids = ReviewScheduler.missing(await items(), exists);
        if (ids.isEmpty) return 0;
        await (_db.update(_db.reviewItem)..where((t) => t.itemId.isIn(ids)))
            .write(const ReviewItemCompanion(retired: Value(1)));
        return ids.length;
      });

  /// The review attempt to open now: today's unfinished session if any of
  /// its items is unanswered, else a new plan (docs/07 §5.3). `null` when
  /// nothing is due.
  Future<int?> startSession(ReviewCatalog catalog, Random random) =>
      _db.transaction(() async {
        final now = _clock.now();
        final day = reviewDayKey(now);
        final open =
            await (_db.select(_db.quizAttempt)
                  ..where(
                    (t) =>
                        t.kind.equals(QuizKind.review.name) &
                        t.refId.equals(day) &
                        t.finishedAt.isNull(),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.id)])
                  ..limit(1))
                .getSingleOrNull();
        if (open != null) return open.id;
        final plan = ReviewScheduler.plan(
          await items(),
          now: now,
          max: await maxPerSession(),
          exists: catalog.exists,
          random: random,
        );
        if (plan.itemIds.isEmpty) return null;
        return _db
            .into(_db.quizAttempt)
            .insert(
              QuizAttemptCompanion.insert(
                kind: QuizKind.review.name,
                refId: day,
                startedAt: isoUtc(now),
                questionIds: jsonEncode(plan.itemIds),
              ),
            );
      });

  /// One checked answer in a review session: stores `quiz_answer`, then
  /// promotes (right) or resets (wrong) the item; `times_seen += 1`.
  Future<TierChange> recordAnswer({
    required int attemptId,
    required String itemId,
    required List<String> answer,
    required bool correct,
    String? sourceLesson,
  }) => _db.transaction(() async {
    final now = _clock.now();
    await _db
        .into(_db.quizAnswer)
        .insertOnConflictUpdate(
          QuizAnswerCompanion.insert(
            attemptId: attemptId,
            questionId: itemId,
            answer: jsonEncode(answer),
            correct: correct ? 1 : 0,
            answeredAt: isoUtc(now),
          ),
        );
    final existing = await item(itemId);
    final next =
        ReviewScheduler.next(
          existing?.state,
          correct: correct,
          mode: ReviewAnswerMode.review,
          now: now,
        ) ??
        existing?.state ??
        ReviewScheduler.onWrong(null, now);
    await _write(
      itemId,
      termSlugOf(itemId) == null ? 'question' : 'term',
      existing?.sourceLesson ?? sourceLesson,
      next,
      (existing?.timesSeen ?? 0) + 1,
    );
    return TierChange(existing?.state, next);
  });

  /// Closes the session with its score and logs `review_finished`.
  Future<void> finishSession(
    int attemptId, {
    required int score,
    required int total,
  }) => _db.transaction(() async {
    final now = isoUtc(_clock.now());
    await (_db.update(_db.quizAttempt)..where((t) => t.id.equals(attemptId)))
        .write(
          QuizAttemptCompanion(
            finishedAt: Value(now),
            score: Value(score),
            total: Value(total),
          ),
        );
    await _db
        .into(_db.event)
        .insert(
          EventCompanion.insert(
            ts: now,
            kind: 'review_finished',
            ref: Value('$attemptId'),
            value: Value(total == 0 ? 0 : score / total),
          ),
        );
  });

  /// Latest finished, scored attempts (lesson, module, review), newest first.
  Stream<List<QuizHistoryEntry>> watchHistory({int limit = 10}) {
    final q = _db.select(_db.quizAttempt)
      ..where(
        (t) =>
            t.finishedAt.isNotNull() &
            t.score.isNotNull() &
            t.total.isNotNull() &
            t.kind.isIn([
              QuizKind.lesson.name,
              QuizKind.module.name,
              QuizKind.review.name,
            ]),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.finishedAt), (t) => OrderingTerm.desc(t.id)])
      ..limit(limit);
    return q.watch().map(
      (rows) => List.unmodifiable([
        for (final r in rows)
          QuizHistoryEntry(
            kind: QuizKind.values.byName(r.kind),
            refId: r.refId,
            finishedAt: DateTime.parse(r.finishedAt!),
            score: r.score!,
            total: r.total!,
          ),
      ]),
    );
  }

  /// `vocab_seen`, oldest first.
  Stream<List<VocabSeenData>> watchVocab() =>
      (_db.select(_db.vocabSeen)..orderBy([(t) => OrderingTerm.asc(t.seenAt)]))
          .watch();

  Future<void> _write(
    String itemId,
    String kind,
    String? sourceLesson,
    ReviewState s,
    int timesSeen,
  ) => _db
      .into(_db.reviewItem)
      .insertOnConflictUpdate(
        ReviewItemCompanion(
          itemId: Value(itemId),
          kind: Value(kind),
          sourceLesson: Value(sourceLesson),
          tier: Value(s.tier),
          dueAt: Value(isoUtc(s.dueAt)),
          lastResult: Value(s.lastResult),
          timesSeen: Value(timesSeen),
          retired: Value(s.retired ? 1 : 0),
        ),
      );
}

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(appDatabaseProvider), ref.watch(clockProvider)),
);

/// Shuffles the session order (DECISIONS.md E7: override with a seeded
/// Random in tests).
final reviewRandomProvider = Provider<Random>((ref) => Random());

final reviewItemsProvider = StreamProvider<List<ReviewItemRecord>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchItems(),
);

final reviewMaxProvider = FutureProvider<int>(
  (ref) => ref.watch(reviewRepositoryProvider).maxPerSession(),
);

final reviewCatalogProvider = Provider<ReviewCatalog>(
  (ref) => ReviewCatalog(ref.watch(contentProvider).requireValue),
);

/// Retires items whose question/term left the content; runs once per load.
final reviewSyncProvider = FutureProvider<int>((ref) async {
  await ref.watch(contentProvider.future);
  final catalog = ref.watch(reviewCatalogProvider);
  return ref.read(reviewRepositoryProvider).retireMissing(catalog.exists);
});

/// The current review day (04:00 boundary). Rechecked when the app comes
/// back to the foreground, so a morning resume shows the new due items.
class ReviewDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);
    return reviewDayStart(ref.watch(clockProvider).now());
  }

  void refresh() {
    final day = reviewDayStart(ref.read(clockProvider).now());
    if (!day.isAtSameMomentAs(state)) state = day;
  }
}

final reviewDayProvider = NotifierProvider<ReviewDayNotifier, DateTime>(
  ReviewDayNotifier.new,
);

final reviewOverviewProvider = Provider<AsyncValue<ReviewOverview>>((ref) {
  final content = ref.watch(contentProvider);
  final items = ref.watch(reviewItemsProvider);
  final max = ref.watch(reviewMaxProvider);
  ref.watch(reviewDayProvider);
  for (final AsyncValue<Object?> a in [content, items, max]) {
    if (a.hasError) return AsyncError(a.error!, a.stackTrace!);
  }
  if (!content.hasValue || !items.hasValue || !max.hasValue) {
    return const AsyncLoading();
  }
  final catalog = ref.watch(reviewCatalogProvider);
  final now = ref.read(clockProvider).now();
  final due = ReviewScheduler.due(items.value!, now, catalog.exists);
  return AsyncData(
    ReviewOverview(
      dueTotal: due.length,
      sessionSize: min(due.length, max.value!),
      lessons: {for (final i in due) i.sourceLesson ?? i.itemId}.length,
      upcoming: ReviewScheduler.upcoming(items.value!, now, catalog.exists),
    ),
  );
});

final reviewHistoryProvider = StreamProvider<List<QuizHistoryEntry>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchHistory(),
);

final vocabSeenProvider = StreamProvider<List<VocabSeenData>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchVocab(),
);

/// Starts or resumes today's review session; returns its attempt id.
Future<int?> startReviewSession(WidgetRef ref) async {
  final content = await ref.read(contentProvider.future);
  await ref.read(reviewSyncProvider.future);
  return ref
      .read(reviewRepositoryProvider)
      .startSession(ReviewCatalog(content), ref.read(reviewRandomProvider));
}
