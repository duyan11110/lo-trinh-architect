// S7 "Từ vựng" — docs/05 S7: terms met so far (`vocab_seen`), grouped by
// track, each row: term · short (reading language) · lesson chip. Quick
// filter on top. Tap → full TermTooltip (with "Thêm vào ôn").
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/review_repository.dart';
import '../../progress/review_scheduler.dart';
import '../../shared/empty_state.dart';
import '../../shared/lesson_link_chip.dart';
import '../../shared/term_tooltip.dart';

/// Lower-cased for the quick filter (no diacritic folding: the same rule as
/// S9, docs/07 §4).
String _fold(String s) => s.toLowerCase();

/// Whether [entry] matches the quick filter [q] (already folded).
bool vocabMatches(GlossaryEntry entry, String q) {
  if (q.isEmpty) return true;
  return [
    entry.term,
    entry.en,
    entry.vi,
    entry.shortVi,
    entry.shortEn,
    ...entry.aliases,
  ].any((s) => _fold(s).contains(q));
}

class VocabView extends ConsumerStatefulWidget {
  const VocabView({super.key});

  @override
  ConsumerState<VocabView> createState() => _VocabViewState();
}

class _VocabViewState extends ConsumerState<VocabView> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final content = ref.watch(contentProvider);
    final seen = ref.watch(vocabSeenProvider);
    if (!content.hasValue || !seen.hasValue) {
      if (content.hasError || seen.hasError) {
        return Center(child: Text(l.contentLoadFailed));
      }
      return const Center(child: CircularProgressIndicator());
    }
    final ct = content.value!;
    final lang = effectiveLang(ref, context);
    final reviewTerms = {
      for (final i in ref.watch(reviewItemsProvider).value ?? const <ReviewItemRecord>[])
        if (i.isTerm && !i.state.retired) i.itemId,
    };

    final entries = <GlossaryEntry>[];
    for (final v in seen.value!) {
      final e = ct.glossaryEntry(v.term!);
      if (e == null) {
        debugPrint('vocab_seen: "${v.term}" not in glossary');
        continue;
      }
      entries.add(e);
    }
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: LtaSpace.contentMobile),
        child: EmptyState(body: l.vocabEmpty),
      );
    }

    final q = _fold(_filter.text.trim());
    final shown = [for (final e in entries) if (vocabMatches(e, q)) e];
    final byTrack = <String, List<GlossaryEntry>>{};
    for (final e in shown) {
      (byTrack[ct.trackOfTerm(e) ?? ''] ??= []).add(e);
    }
    final order = [
      for (final t in ct.tracks)
        if (byTrack.containsKey(t.id)) t.id,
      if (byTrack.containsKey('')) '',
    ];
    for (final list in byTrack.values) {
      list.sort((a, b) => _fold(a.name(lang)).compareTo(_fold(b.name(lang))));
    }

    void open(GlossaryEntry e) => showTermTooltip(
      context,
      entry: e,
      lang: lang,
      learnedInTitle: ct.lessonTitle(e.introducedIn)?.of(lang),
      learnedInAvailable: ct.lessons.containsKey(e.introducedIn),
      onOpenLesson: (id) => context.push(lessonLocation(id)),
      inReview: reviewTerms.contains(termItemId(e.term)),
      onAddReview: (e) => ref.read(reviewRepositoryProvider).addTerm(e),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: LtaSpace.contentMobile,
        vertical: LtaSpace.s4,
      ),
      children: [
        TextField(
          controller: _filter,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l.vocabSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: LtaSpace.s3),
        if (shown.isEmpty) EmptyState(body: l.vocabNoMatch(_filter.text.trim())),
        for (final t in order) ...[
          const SizedBox(height: LtaSpace.s4),
          Text(
            t.isEmpty ? '' : (ct.track(t)?.title.of(lang) ?? t),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: LtaSpace.s1),
          for (final e in byTrack[t]!)
            InkWell(
              key: ValueKey('vocab-${e.term}'),
              onTap: () => open(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: LtaSpace.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name(lang),
                      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      e.short(lang),
                      style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
                    ),
                    const SizedBox(height: LtaSpace.s1),
                    LessonLinkChip(
                      lessonId: e.introducedIn,
                      title: ct.lessonTitle(e.introducedIn)?.of(lang),
                      available: ct.lessons.containsKey(e.introducedIn),
                      onTap: () => context.push(lessonLocation(e.introducedIn)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
