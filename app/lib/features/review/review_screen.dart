// S7 Ôn tập (`/review`, `/review/vocab`) — docs/05 S7: [Hôm nay|Từ vựng].
// Hôm nay: due today (count, lessons, ~minutes, "Bắt đầu ôn", "còn N câu, ôn
// tiếp sau" when the session is cut), "Sắp tới" as one line of text, quiz
// history. Empty: docs/05 §7 copy + "Học tiếp". Từ vựng: vocab_view.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/clock.dart';
import '../../progress/quiz_repository.dart';
import '../../progress/review_repository.dart';
import '../../progress/review_scheduler.dart';
import '../../shared/empty_state.dart';
import 'vocab_view.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, this.vocab = false});

  /// The "Từ vựng" tab (`/review/vocab`).
  final bool vocab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    // Content updates retire items whose question is gone (docs/07 §5.3).
    ref.watch(reviewSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navReview),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: LtaSpace.s3),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l.reviewTabToday)),
                ButtonSegment(value: true, label: Text(l.reviewTabVocab)),
              ],
              selected: {vocab},
              onSelectionChanged: (s) =>
                  context.go(s.first ? reviewVocabLocation : reviewLocation),
            ),
          ),
        ],
      ),
      body: vocab ? const VocabView() : const _TodayView(),
    );
  }
}

class _TodayView extends ConsumerWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final overview = ref.watch(reviewOverviewProvider);
    final history = ref.watch(reviewHistoryProvider).value ?? const [];
    return overview.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        debugPrint('review load failed: $e');
        return Center(child: Text(l.contentLoadFailed));
      },
      data: (o) {
        final content = ref.watch(contentProvider).requireValue;
        final lang = effectiveLang(ref, context);
        final now = ref.read(clockProvider).now();
        final empty = o.dueTotal == 0 && o.upcoming.isEmpty;
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: LtaSpace.contentMobile,
            vertical: LtaSpace.s4,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: LtaSize.homeMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (empty)
                      EmptyState(
                        body: l.reviewEmpty,
                        action: FilledButton(
                          onPressed: () => context.go(homeLocation),
                          child: Text(l.navContinue),
                        ),
                      )
                    else ...[
                      if (o.dueTotal > 0) _DueCard(overview: o),
                      if (o.upcoming.isNotEmpty) ...[
                        const SizedBox(height: LtaSpace.s6),
                        _Heading(l.reviewUpcoming),
                        Text(_upcomingLine(l, o.upcoming, now)),
                      ],
                    ],
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: LtaSpace.s6),
                      _Heading(l.reviewHistory),
                      for (final h in history)
                        _HistoryRow(entry: h, content: content, lang: lang, now: now),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// "Ngày mai 4 · T4 9 · T7 2" — the next five review days with items.
  static String _upcomingLine(L l, List<(int, int)> upcoming, DateTime now) {
    final day0 = reviewDayStart(now);
    return [
      for (final (days, count) in upcoming.take(5))
        l.reviewUpcomingItem(
          days == 1
              ? l.reviewTomorrow
              : days < 7
              ? l.reviewWeekday(
                  '${DateTime(day0.year, day0.month, day0.day + days).weekday}',
                )
              : _date(DateTime(day0.year, day0.month, day0.day + days)),
          count,
        ),
    ].join(' · ');
  }
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: LtaSpace.s2),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _DueCard extends ConsumerWidget {
  const _DueCard({required this.overview});

  final ReviewOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final o = overview;
    return Container(
      padding: const EdgeInsets.all(LtaSpace.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LtaRadius.card),
        border: Border.all(color: c.line, width: LtaSize.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.reviewDueToday, style: theme.textTheme.titleLarge)),
              Text(l.reviewCount(o.dueTotal), style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: LtaSpace.s1),
          Text(
            l.reviewDueMeta(o.lessons, o.minutes),
            style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
          ),
          if (o.remaining > 0) ...[
            const SizedBox(height: LtaSpace.s1),
            Text(
              l.reviewRemaining(o.remaining),
              style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
            ),
          ],
          const SizedBox(height: LtaSpace.s4),
          SizedBox(
            height: LtaSize.minTouch,
            child: FilledButton(
              onPressed: () async {
                final id = await startReviewSession(ref);
                if (id != null && context.mounted) {
                  context.push(reviewSessionLocation(id));
                }
              },
              child: Text(l.reviewStart),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.content,
    required this.lang,
    required this.now,
  });

  final QuizHistoryEntry entry;
  final Content content;
  final ContentLang lang;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final days = reviewDaysBetween(entry.finishedAt, now);
    final local = entry.finishedAt.toLocal();
    final when = days <= 0
        ? l.reviewHistoryToday
        : days == 1
        ? l.reviewHistoryYesterday
        : _date(local);
    final title = switch (entry.kind) {
      QuizKind.review => l.reviewHistorySession,
      QuizKind.module => content.module(entry.refId)?.title.of(lang) ?? entry.refId,
      _ => content.lessonTitle(entry.refId)?.of(lang) ?? entry.refId,
    };
    final muted = theme.textTheme.bodyMedium!.copyWith(color: c.ink2);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LtaSize.minTap),
      child: Row(
        children: [
          SizedBox(width: LtaSpace.s7 + LtaSpace.s5, child: Text(when, style: muted)),
          SizedBox(
            width: LtaSpace.s7,
            child: Text(l.reviewHistoryScore(entry.score, entry.total)),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
