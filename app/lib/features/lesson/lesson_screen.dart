// S3 Đọc bài (`/learn/:lessonId`) — docs/05 S3. Reads a lesson in VI/EN with
// the full §3 grammar (M1); lesson progress (docs/07 §5.1), BottomActionBar
// by status and the `Aa` sheet (M2); the quiz buttons open S4 (M3); the
// prereq dialog S5 before rendering (M4). M7 (docs/05 S3 Web, §9): from
// 900 dp a sticky table of contents on the left (current section bold) and
// a 72 ch column; from 1100 dp the meta card on the right; keys `j/k`
// section, `n` next lesson, `q` quiz, `l` language, `/` search.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/markdown/prose.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/learning_plan.dart';
import '../../progress/plan_provider.dart';
import '../../progress/progress_repository.dart';
import '../../progress/review_repository.dart';
import '../../progress/review_scheduler.dart';
import '../../shared/bottom_action_bar.dart';
import '../../shared/key_shortcuts.dart';
import '../../shared/lesson_link_chip.dart';
import '../../shared/lang_toggle.dart';
import '../../shared/status_dot.dart';
import 'prereq_dialog.dart';

export '../../app/locations.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId, this.initialSection});

  final String lessonId;

  /// `#s4` → 4 (docs/05 §3.2).
  final int? initialSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final content = ref.watch(contentProvider);
    return content.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) {
        debugPrint('content load failed: $e');
        return _Message(
          text: l.contentLoadFailed,
          action: TextButton(
            onPressed: () => ref.invalidate(contentProvider),
            child: Text(l.contentRetry),
          ),
        );
      },
      data: (c) {
        final lesson = c.lessons[lessonId];
        if (lesson == null) return _Message(text: l.lessonNotFound);
        return PrereqGate(
          key: ValueKey(lesson.id),
          content: c,
          lesson: lesson,
          child: _LessonView(
            content: c,
            lesson: lesson,
            initialSection: initialSection,
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(LtaSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: LtaSpace.s4),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}

class _LessonView extends ConsumerStatefulWidget {
  const _LessonView({
    required this.content,
    required this.lesson,
    required this.initialSection,
  });

  final Content content;
  final Lesson lesson;
  final int? initialSection;

  @override
  ConsumerState<_LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends ConsumerState<_LessonView> {
  final _scroll = ScrollController();
  final _sectionKeys = <int, GlobalKey>{};
  final _summaryKey = GlobalKey();
  late final ProgressRepository _repo;

  /// Section numbers in reading order (from the last build).
  List<int> _order = const [];

  /// Section at the top of the viewport (TOC highlight, `j/k`).
  int? _current;

  /// Already `read`/`passed`, or the read transition was requested.
  bool _readMarked = false;
  bool _barVisible = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(progressRepositoryProvider);
    _scroll.addListener(_onScroll);
    _open();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// docs/07 §5.1: opening → `opened`; restores the saved scroll ratio unless
  /// a `#sN` fragment asks for a section (docs/05 S3).
  Future<void> _open() async {
    final id = widget.lesson.id;
    final before = await _repo.get(id);
    await _repo.markOpened(id);
    if (!mounted) return;
    if (before != null && before.status.atLeast(LessonStatus.read)) {
      _readMarked = true;
    }
    final n = widget.initialSection;
    final ratio = before?.scrollRatio ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (n != null) {
        _scrollToSection(n);
      } else if (ratio > 0 && _scroll.hasClients) {
        _scroll.jumpTo(ratio * _scroll.position.maxScrollExtent);
      }
      _onScroll();
    });
  }

  double get _ratio {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return 0;
    final max = _scroll.position.maxScrollExtent;
    return max <= 0 ? 1 : (_scroll.offset / max).clamp(0.0, 1.0);
  }

  void _onScroll() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    final visible = _ratio >= LtaSize.actionBarScroll;
    if (visible != _barVisible) setState(() => _barVisible = visible);
    if (!_readMarked && _summaryInView()) _markRead();
    final current = _sectionAtTop();
    if (current != _current) setState(() => _current = current);
  }

  /// Offset of section [n]'s heading from the top of the viewport.
  double? _sectionTop(int n) {
    final box = _sectionKeys[n]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    return viewport.getOffsetToReveal(box, 0).offset - _scroll.offset;
  }

  /// Last section whose heading has reached the top area of the viewport.
  int? _sectionAtTop() {
    int? current;
    for (final n in _order) {
      final top = _sectionTop(n);
      if (top == null) continue;
      if (top <= LtaSpace.s7) {
        current = n;
      } else {
        break;
      }
    }
    return current ?? _order.firstOrNull;
  }

  /// `j` (+1) / `k` (−1): scroll to the next/previous section.
  void _stepSection(int delta) {
    if (_order.isEmpty) return;
    final i = _current == null ? -1 : _order.indexOf(_current!);
    final next = (i + delta).clamp(0, _order.length - 1);
    _scrollToSection(_order[next]);
  }

  /// docs/07 §5.1: the Summary section is ≥ 50% inside the viewport (of its
  /// own height, or of the viewport when it is taller than the screen).
  bool _summaryInView() {
    final box = _summaryKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return false;
    final top = viewport.getOffsetToReveal(box, 0).offset - _scroll.offset;
    final h = box.size.height;
    final vh = _scroll.position.viewportDimension;
    final shown = math.min(top + h, vh) - math.max(top, 0.0);
    return shown >= 0.5 * math.min(h, vh);
  }

  void _markRead() {
    _readMarked = true;
    _repo.markRead(widget.lesson.id, vocab: widget.lesson.vocab);
  }

  void _scrollToSection(int n) {
    final ctx = _sectionKeys[n]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx);
    if (_current != n) setState(() => _current = n);
  }

  /// Switching language keeps the scroll ratio, not the pixel offset
  /// (docs/05 S3).
  void _setLang(ContentLang lang) {
    double? ratio;
    if (_scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
      ratio = _scroll.offset / _scroll.position.maxScrollExtent;
    }
    ref.read(contentLangProvider.notifier).set(lang);
    if (ratio == null) return;
    final r = ratio;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(r * _scroll.position.maxScrollExtent);
      }
    });
  }

  ProseLinks _links(
    BuildContext context,
    ContentLang lang,
    Map<String, LessonRecord> progress,
    Set<String> reviewTerms,
  ) => ProseLinks(
    titleOf: (id) => widget.content.lessonTitle(id)?.of(lang),
    isAvailable: widget.content.lessons.containsKey,
    statusOf: (id) => progress[id]?.status ?? LessonStatus.newLesson,
    onOpen: (id) => context.push(lessonLocation(id)),
    inReview: (term) => reviewTerms.contains(termItemId(term)),
    onAddReview: (entry) => ref.read(reviewRepositoryProvider).addTerm(entry),
  );

  void _showReadingSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ReadingSheet(),
    );
  }

  /// Summary section number (docs/01: 9 for L1–L3, 11 for L4); the last
  /// section when the lesson has no summary slot.
  int? _summaryN(List<ParsedSection> parsed) {
    int? n;
    for (final s in parsed) {
      final role = SectionRole.of(level: widget.lesson.level, n: s.section.n);
      if (role == SectionRole.summary) n = s.section.n;
    }
    return n ?? (parsed.isEmpty ? null : parsed.last.section.n);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final lang = effectiveLang(ref, context);
    final prefs = ref.watch(readingPrefsProvider);
    final lesson = widget.lesson;
    final progress =
        ref.watch(lessonProgressProvider).value ??
        const <String, LessonRecord>{};
    final record = progress[lesson.id];
    final position = lessonPosition(widget.content, lesson.id);
    final moduleTitle = position?.module.title.of(lang) ?? lesson.module;
    final parsed = ref
        .watch(proseCacheProvider)
        .get(lesson, lang, ref.watch(glossaryMatcherProvider(lang)));
    final reviewTerms = {
      for (final i
          in ref.watch(reviewItemsProvider).value ?? const <ReviewItemRecord>[])
        if (i.isTerm && !i.state.retired) i.itemId,
    };
    final links = _links(context, lang, progress, reviewTerms);
    final summaryN = _summaryN(parsed);
    _order = [for (final s in parsed) s.section.n];
    final layout = LtaLayout.of(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l
              .lessonEyebrow(lesson.stage, moduleTitle, lesson.durationMin)
              .toUpperCase(),
          style: t.eyebrow,
        ),
        const SizedBox(height: LtaSpace.s2),
        Text(lesson.title.of(lang), style: theme.textTheme.headlineMedium),
        if (record?.isUpdatedSincePassed(lesson.contentVersion) ?? false) ...[
          const SizedBox(height: LtaSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LtaSpace.s2,
                vertical: LtaSpace.s1,
              ),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(LtaRadius.chip),
              ),
              child: Text(
                l.lessonUpdated.toUpperCase(),
                style: t.eyebrow.copyWith(color: c.accent),
              ),
            ),
          ),
        ],
        if (lesson.skipNote != null) ...[
          const SizedBox(height: LtaSpace.s3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LtaSpace.s3,
              vertical: LtaSpace.s2,
            ),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(LtaRadius.button),
            ),
            child: Text(
              l.lessonOptional(lesson.skipNote!.of(lang)),
              style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
            ),
          ),
        ],
        for (final s in parsed)
          Column(
            key: s.section.n == summaryN ? _summaryKey : null,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: LtaSpace.s6),
              Text(
                s.section.heading,
                key: _sectionKeys.putIfAbsent(s.section.n, GlobalKey.new),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: LtaSpace.s3),
              Prose(
                blocks: s.blocks,
                lang: lang,
                links: links,
                role: SectionRole.of(level: lesson.level, n: s.section.n),
                lessonId: lesson.id,
                diagramSvg: lesson.diagramSvg,
                fontSize: prefs.fontSize,
                lineHeight: prefs.lineHeight,
              ),
            ],
          ),
        const SizedBox(height: LtaSpace.s7),
      ],
    );

    final scrollView = NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _repo.saveScroll(lesson.id, _ratio);
        return false;
      },
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.symmetric(
          horizontal: layout.margin,
          vertical: LtaSpace.s4,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: layout.twoColumn
                  ? _measure(context, prefs.fontSize)
                  : LtaSize.readingMaxWidth,
            ),
            child: kIsWeb ? SelectionArea(child: body) : body,
          ),
        ),
      ),
    );

    final status = record?.status ?? LessonStatus.opened;
    final quiz = widget.content.quizzes[lesson.id];
    final plan = ref.watch(learningPlanProvider).value?.next;
    final nextId = plan != null && plan.id != lesson.id ? plan.id : null;
    // One Row at every width (keyed children) so resizing across 900 dp
    // keeps the same scroll view and its controller.
    final Widget readingBody = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (layout.twoColumn)
          SizedBox(
            key: const ValueKey('toc'),
            width: layout == LtaLayout.wide ? LtaSize.tocWide : LtaSize.tocRail,
            child: _Toc(
              sections: [for (final s in parsed) s.section],
              current: _current,
              onTap: _scrollToSection,
            ),
          ),
        Expanded(key: const ValueKey('reading'), child: scrollView),
        if (layout == LtaLayout.wide)
          SizedBox(
            key: const ValueKey('meta'),
            width: LtaSize.lessonMeta,
            child: _MetaPanel(
              content: widget.content,
              lesson: lesson,
              lang: lang,
              moduleTitle: moduleTitle,
              progress: progress,
              onOpen: (id) => context.push(lessonLocation(id)),
            ),
          ),
      ],
    );
    return KeyShortcuts(
      bindings: {
        const CharacterActivator('j'): () => _stepSection(1),
        const CharacterActivator('k'): () => _stepSection(-1),
        const CharacterActivator('n', includeRepeats: false): () {
          if (nextId != null) context.pushReplacement(lessonLocation(nextId));
        },
        const CharacterActivator('q', includeRepeats: false): () {
          if (quiz != null) context.push(quizLocation(lesson.id));
        },
        const CharacterActivator('l', includeRepeats: false): () =>
            _setLang(lang == ContentLang.vi ? ContentLang.en : ContentLang.vi),
        const CharacterActivator('/', includeRepeats: false): () =>
            context.go(searchLocation()),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            position == null
                ? moduleTitle
                : l.lessonPosition(moduleTitle, position.index, position.total),
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            LangToggle(lang: lang, onChanged: _setLang),
            IconButton(
              tooltip: l.readingSettings,
              icon: const Icon(Icons.text_fields_rounded),
              onPressed: _showReadingSheet,
            ),
            const SizedBox(width: LtaSpace.s1),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(LtaSize.readingProgress),
            child: _ReadingProgress(controller: _scroll),
          ),
        ),
        body: MediaQuery.withClampedTextScaling(
          maxScaleFactor: LtaText.maxTextScale,
          child: readingBody,
        ),
        bottomNavigationBar: _barVisible
            ? _LessonActions(
                content: widget.content,
                lesson: lesson,
                status: status,
                onMarkRead: _markRead,
              )
            : null,
      ),
    );
  }

  /// 72 ch of the reading font (docs/05 S3 Web, §9).
  double _measure(BuildContext context, double fontSize) {
    final style = Theme.of(context).textTheme.bodyLarge!
        .copyWith(fontSize: fontSize);
    final painter = TextPainter(
      text: TextSpan(text: '0' * LtaSize.readingMeasureCh, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: LtaText.maxTextScale),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// Table of contents (docs/05 S3 Web): sticky, the section being read bold.
class _Toc extends StatelessWidget {
  const _Toc({
    required this.sections,
    required this.current,
    required this.onTap,
  });

  final List<LessonSection> sections;
  final int? current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: LtaSpace.s3,
        vertical: LtaSpace.s5,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LtaSpace.s3),
          child: Text(L.of(context).lessonToc.toUpperCase(), style: t.eyebrow),
        ),
        const SizedBox(height: LtaSpace.s2),
        for (final s in sections)
          Semantics(
            selected: s.n == current,
            button: true,
            child: InkWell(
              key: ValueKey('toc-${s.n}'),
              borderRadius: BorderRadius.circular(LtaRadius.button),
              onTap: () => onTap(s.n),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LtaSpace.s3,
                  vertical: LtaSpace.s2,
                ),
                child: Text(
                  s.heading,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: s.n == current ? c.ink : c.ink2,
                    fontWeight: s.n == current ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Meta card (docs/05 S3 Web ≥ 1100): module, skills, duration, prereqs,
/// related.
class _MetaPanel extends StatelessWidget {
  const _MetaPanel({
    required this.content,
    required this.lesson,
    required this.lang,
    required this.moduleTitle,
    required this.progress,
    required this.onOpen,
  });

  final Content content;
  final Lesson lesson;
  final ContentLang lang;
  final String moduleTitle;
  final Map<String, LessonRecord> progress;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final t = theme.extension<LtaText>()!;
    final skills = {for (final s in content.skills) s.id: s};

    Widget group(String label, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: LtaSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.eyebrow),
          const SizedBox(height: LtaSpace.s1),
          ...children,
        ],
      ),
    );

    Widget chips(List<String> ids) => Wrap(
      spacing: LtaSpace.s2,
      runSpacing: LtaSpace.s2,
      children: [
        for (final id in ids)
          LessonLinkChip(
            lessonId: id,
            title: content.lessonTitle(id)?.of(lang),
            available: content.lessons.containsKey(id),
            status: progress[id]?.status ?? LessonStatus.newLesson,
            onTap: () => onOpen(id),
          ),
      ],
    );

    final body = theme.textTheme.bodyMedium!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        0,
        LtaSpace.s5,
        LtaSpace.s5,
        LtaSpace.s5,
      ),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(LtaSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                group(l.lessonMetaModule, [Text(moduleTitle, style: body)]),
                if (lesson.skills.isNotEmpty)
                  group(l.resultSkills, [
                    for (final id in lesson.skills)
                      Text(skills[id]?.title.of(lang) ?? id, style: body),
                  ]),
                group(l.lessonMetaDuration, [
                  Text(l.durationMinutes(lesson.durationMin), style: body),
                ]),
                if (lesson.prereqs.isNotEmpty)
                  group(l.lessonMetaPrereqs, [chips(lesson.prereqs)]),
                if (lesson.related.isNotEmpty)
                  group(l.lessonMetaRelated, [chips(lesson.related)]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// BottomActionBar of S3 by lesson status (docs/05 S3 Trạng thái).
class _LessonActions extends ConsumerWidget {
  const _LessonActions({
    required this.content,
    required this.lesson,
    required this.status,
    required this.onMarkRead,
  });

  final Content content;
  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final quiz = content.quizzes[lesson.id];
    final last = ref.watch(lastLessonScoreProvider(lesson.id)).value;
    final next = ref.watch(learningPlanProvider).value?.next;
    final nextId = next != null && next.id != lesson.id ? next.id : null;
    final goNext = nextId == null
        ? null
        : FilledButton(
            onPressed: () => context.pushReplacement(lessonLocation(nextId)),
            child: Text(l.lessonNextLesson),
          );

    void takeQuiz() => context.push(quizLocation(lesson.id));

    if (status == LessonStatus.passed) {
      final retake = quiz == null
          ? null
          : OutlinedButton(
              onPressed: takeQuiz,
              child: Text(l.lessonRetakeQuiz),
            );
      if (goNext != null) {
        return BottomActionBar(primary: goNext, secondary: retake);
      }
      return retake == null
          ? const SizedBox.shrink()
          : BottomActionBar(primary: retake);
    }

    final markRead = status.atLeast(LessonStatus.read)
        ? null
        : TextButton(onPressed: onMarkRead, child: Text(l.lessonMarkRead));
    if (quiz == null) {
      final primary = markRead ?? goNext;
      return primary == null
          ? const SizedBox.shrink()
          : BottomActionBar(primary: primary);
    }
    return BottomActionBar(
      primary: FilledButton(
        onPressed: takeQuiz,
        child: Text(l.lessonTakeQuiz(quiz.questions.length)),
      ),
      note: status == LessonStatus.read && last != null
          ? l.lessonLastAttempt(last.score, last.total)
          : null,
      secondary: markRead,
    );
  }
}

/// `Aa` bottom sheet: 4 font sizes, 2 line heights, applied immediately
/// (docs/05 S3).
class _ReadingSheet extends ConsumerWidget {
  const _ReadingSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final prefs = ref.watch(readingPrefsProvider);
    final notifier = ref.read(readingPrefsProvider.notifier);
    String num(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LtaSpace.contentMobile,
          0,
          LtaSpace.contentMobile,
          LtaSpace.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.readingSettings, style: theme.textTheme.titleMedium),
            const SizedBox(height: LtaSpace.s3),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < ReadingPrefs.steps.length; i++)
                  ButtonSegment(
                    value: i,
                    label: Text(num(ReadingPrefs.steps[i])),
                  ),
              ],
              selected: {prefs.fontStep},
              onSelectionChanged: (v) => notifier.setFontStep(v.first),
            ),
            const SizedBox(height: LtaSpace.s5),
            Text(l.readingLineHeight, style: theme.textTheme.titleMedium),
            const SizedBox(height: LtaSpace.s3),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < LtaText.readingLineHeights.length; i++)
                  ButtonSegment(
                    value: i,
                    label: Text(num(LtaText.readingLineHeights[i])),
                  ),
              ],
              selected: {prefs.lineStep},
              onSelectionChanged: (v) => notifier.setLineStep(v.first),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2 dp bar following the scroll position; hidden from semantics.
class _ReadingProgress extends StatelessWidget {
  const _ReadingProgress({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    return ExcludeSemantics(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          var v = 0.0;
          if (controller.hasClients &&
              controller.position.hasContentDimensions &&
              controller.position.maxScrollExtent > 0) {
            v = (controller.offset / controller.position.maxScrollExtent).clamp(
              0.0,
              1.0,
            );
          }
          return Container(
            height: LtaSize.readingProgress,
            color: c.line,
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: v,
              child: Container(color: c.accent),
            ),
          );
        },
      ),
    );
  }
}
