// S9 Tìm (`/search?q=`) — docs/05 S9: auto-focused field; searches from 2
// characters (FTS5 prefix, search_index.dart); results grouped by track,
// each: title · GĐ · status · matched excerpt (highlighted); filter chips
// stage / track / "chưa học"; empty → docs/05 §7 copy. "Đang lập chỉ mục…"
// until the index matches the content (docs/07 §8).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../content/search_index.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/progress_repository.dart';
import '../../shared/empty_state.dart';
import '../../shared/highlighted_text.dart';
import '../../shared/status_dot.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _query;
  List<SearchHit> _hits = const [];
  String _searched = '';
  int _seq = 0;
  int? _stage;
  String? _track;
  bool _notLearned = false;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _query.text;
    final seq = ++_seq;
    if (ftsQuery(text) == null) {
      setState(() {
        _hits = const [];
        _searched = '';
      });
      return;
    }
    await ref.read(searchIndexProvider.future);
    if (!mounted) return;
    final hits = await ref
        .read(searchIndexServiceProvider)
        .search(text, effectiveLang(ref, context));
    if (!mounted || seq != _seq) return;
    setState(() {
      _hits = hits;
      _searched = text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final index = ref.watch(searchIndexProvider);
    final content = ref.watch(contentProvider).value;
    final progress =
        ref.watch(lessonProgressProvider).value ?? const <String, LessonRecord>{};
    final lang = effectiveLang(ref, context);

    LessonStatus status(String id) => progress[id]?.status ?? LessonStatus.newLesson;

    final hits = content == null
        ? const <SearchHit>[]
        : [
            for (final h in _hits)
              if (content.lessons[h.lessonId] case final lesson?)
                if ((_stage == null || lesson.stage == _stage) &&
                    (_track == null || lesson.track == _track) &&
                    (!_notLearned || !status(h.lessonId).atLeast(LessonStatus.read)))
                  h,
          ];
    final byTrack = <String, List<SearchHit>>{};
    for (final h in hits) {
      (byTrack[content!.lessons[h.lessonId]!.track] ??= []).add(h);
    }

    final Widget body;
    if (index.isLoading) {
      body = EmptyState(body: l.searchIndexing);
    } else if (index.hasError) {
      body = EmptyState(body: l.contentLoadFailed);
    } else if (_searched.isEmpty) {
      body = const SizedBox.shrink();
    } else if (hits.isEmpty) {
      body = EmptyState(body: l.searchEmpty(_searched));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in content!.tracks)
            if (byTrack[t.id] case final list?) ...[
              const SizedBox(height: LtaSpace.s4),
              Text(t.title.of(lang), style: theme.textTheme.titleMedium),
              for (final h in list)
                _HitRow(
                  hit: h,
                  lesson: content.lessons[h.lessonId]!,
                  status: status(h.lessonId),
                  onTap: () => context.push(lessonLocation(h.lessonId)),
                ),
            ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.navSearch)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: LtaSpace.contentMobile,
          vertical: LtaSpace.s3,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: LtaSize.homeMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('search-field'),
                    controller: _query,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => _run(),
                    onSubmitted: (_) => _run(),
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: LtaSpace.s3),
                    _Filters(
                      content: content,
                      lang: lang,
                      stage: _stage,
                      track: _track,
                      notLearned: _notLearned,
                      onStage: (s) => setState(() => _stage = s),
                      onTrack: (t) => setState(() => _track = t),
                      onNotLearned: (v) => setState(() => _notLearned = v),
                    ),
                  ],
                  body,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.content,
    required this.lang,
    required this.stage,
    required this.track,
    required this.notLearned,
    required this.onStage,
    required this.onTrack,
    required this.onNotLearned,
  });

  final Content content;
  final ContentLang lang;
  final int? stage;
  final String? track;
  final bool notLearned;
  final ValueChanged<int?> onStage;
  final ValueChanged<String?> onTrack;
  final ValueChanged<bool> onNotLearned;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: Text(l.statusNew),
            selected: notLearned,
            onSelected: onNotLearned,
          ),
          for (final s in content.stages) ...[
            const SizedBox(width: LtaSpace.s2),
            FilterChip(
              label: Text(l.pathStageTag(s.stage)),
              selected: stage == s.stage,
              onSelected: (v) => onStage(v ? s.stage : null),
            ),
          ],
          for (final t in content.tracks) ...[
            const SizedBox(width: LtaSpace.s2),
            FilterChip(
              label: Text(t.title.of(lang)),
              selected: track == t.id,
              onSelected: (v) => onTrack(v ? t.id : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({
    required this.hit,
    required this.lesson,
    required this.status,
    required this.onTap,
  });

  final SearchHit hit;
  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final statusText = switch (status) {
      LessonStatus.newLesson => l.statusNew,
      LessonStatus.opened => l.statusOpened,
      LessonStatus.read => l.statusRead,
      LessonStatus.passed => l.statusPassed,
    };
    return InkWell(
      key: ValueKey('search-hit-${hit.lessonId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LtaSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HighlightedText(hit.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: LtaSpace.s1),
            Row(
              children: [
                StatusDot(status: status),
                const SizedBox(width: LtaSpace.s2),
                Text(
                  '${l.pathStageTag(lesson.stage)} · $statusText',
                  style: t.eyebrow,
                ),
              ],
            ),
            if (hit.snippet.isNotEmpty) ...[
              const SizedBox(height: LtaSpace.s1),
              HighlightedText(
                hit.snippet,
                maxLines: 3,
                style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
