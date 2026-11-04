// Review session (`/review/session/:attemptId`) — S4 in mode `review`
// (docs/05 S4, §3.3 "Luồng ôn"): the items stored in the attempt's
// `question_ids`, one per screen; eyebrow "ÔN · <module> · <bài>"; after the
// explanation a line "Bậc 1 → 2 · gặp lại sau 7 ngày" / "Về bậc 0 · gặp lại
// ngày mai"; at the end a short summary "9/12 · 3 câu về bậc 0" → Học tiếp.
// Each answer is stored at once (review_repository.dart), so the session
// resumes after an app kill.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/quiz_repository.dart';
import '../../progress/review_repository.dart';
import '../../progress/review_scheduler.dart';
import '../../shared/bottom_action_bar.dart';
import '../../shared/empty_state.dart';
import '../../shared/lang_toggle.dart';
import '../quiz/explanation_panel.dart';
import '../quiz/question_widgets/question_view.dart';
import '../quiz/quiz_grader.dart';
import '../quiz/quiz_screen.dart';

class ReviewSessionScreen extends ConsumerWidget {
  const ReviewSessionScreen({super.key, required this.attemptId});

  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final content = ref.watch(contentProvider);
    final attempt = ref.watch(quizAttemptProvider(attemptId));
    Widget message(String text) => Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(LtaSpace.contentMobile),
        child: EmptyState(body: text),
      ),
    );
    if (content.hasError) return message(l.contentLoadFailed);
    if (attempt.hasError) return message(l.resultNotFound);
    if (!content.hasValue || !attempt.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final a = attempt.value;
    if (a == null || a.kind != QuizKind.review) return message(l.resultNotFound);
    final catalog = ref.watch(reviewCatalogProvider);
    final items = [
      for (final id in a.questionIds)
        if (catalog.question(id, a.id) case final q?) (q, catalog.sourceLesson(id)),
    ];
    if (items.isEmpty) return message(l.reviewEmpty);
    return _ReviewSession(
      key: ValueKey(a.id),
      attempt: a,
      items: items,
      content: content.value!,
    );
  }
}

class _ReviewSession extends ConsumerStatefulWidget {
  const _ReviewSession({
    super.key,
    required this.attempt,
    required this.items,
    required this.content,
  });

  final QuizAttemptRecord attempt;
  final List<(Question, String?)> items;
  final Content content;

  @override
  ConsumerState<_ReviewSession> createState() => _ReviewSessionState();
}

class _ReviewSessionState extends ConsumerState<_ReviewSession> {
  late final ReviewRepository _repo;
  int _index = 0;
  final _responses = <String, List<String>>{};
  final _checked = <String>{};
  final _results = <String, bool>{};
  final _changes = <String, TierChange>{};
  final _scroll = ScrollController();
  bool _contextExpanded = true;
  bool _finished = false;
  bool _leaving = false;
  Future<void> _pending = Future.value();

  List<(Question, String?)> get _items => widget.items;
  Question get _q => _items[_index].$1;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(reviewRepositoryProvider);
    final a = widget.attempt;
    for (final r in a.answers.values) {
      _responses[r.questionId] = r.answer;
      _checked.add(r.questionId);
      _results[r.questionId] = r.correct;
    }
    final next = _items.indexWhere((i) => !_checked.contains(i.$1.id));
    if (next < 0) {
      _index = _items.length - 1;
      _finished = a.finished;
      if (!a.finished) WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _index = next;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<String> _response(Question q) => _responses[q.id] ?? initialResponse(q);

  void _check() {
    final q = _q;
    final source = _items[_index].$2;
    final response = _response(q);
    final correct = gradeAnswer(q, response);
    setState(() {
      _responses[q.id] = response;
      _checked.add(q.id);
      _results[q.id] = correct;
    });
    _pending = _pending.then((_) async {
      final change = await _repo.recordAnswer(
        attemptId: widget.attempt.id,
        itemId: q.id,
        answer: response,
        correct: correct,
        sourceLesson: source,
      );
      if (mounted) setState(() => _changes[q.id] = change);
    });
  }

  Future<void> _next() async {
    if (_index < _items.length - 1) {
      setState(() => _index++);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_finished) return;
    await _pending;
    await _repo.finishSession(
      widget.attempt.id,
      score: _results.values.where((v) => v).length,
      total: _items.length,
    );
    if (mounted) setState(() => _finished = true);
  }

  void _reread() {
    final source = _items[_index].$2;
    if (source == null) return;
    context.push(lessonLocation(source, section: _q.sectionRef));
  }

  Future<void> _confirmLeave() async {
    final l = L.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.quizLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.quizStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.quizLeave),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    await _pending;
    await ref.read(quizRepositoryProvider).abandon(widget.attempt.id);
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _close();
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(homeLocation);
    }
  }

  String? _note(L l, Question q) {
    final ch = _changes[q.id];
    if (ch == null) return null;
    if (!ch.promoted) return l.reviewTierReset;
    if (ch.retired) return l.reviewTierRetired(ch.fromTier, ch.toTier);
    return l.reviewTierChange(ch.fromTier, ch.toTier, ch.days);
  }

  String _eyebrow(L l, ContentLang lang) {
    final source = _items[_index].$2;
    final lesson = source == null ? null : widget.content.lessons[source];
    final module = lesson == null
        ? null
        : widget.content.module(lesson.moduleKey)?.title.of(lang) ?? lesson.module;
    final title = source == null
        ? null
        : widget.content.lessonTitle(source)?.of(lang) ?? source;
    if (module == null || title == null) {
      return l.reviewEyebrow(l.navReview, title ?? '').toUpperCase();
    }
    return l.reviewEyebrow(module, title).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final lang = effectiveLang(ref, context);
    final total = _items.length;

    if (_finished) {
      final score = _results.values.where((v) => v).length;
      final down = _results.values.where((v) => !v).length;
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text(l.navReview)),
        body: ListView(
          padding: const EdgeInsets.all(LtaSpace.contentMobile),
          children: [
            Text(
              l.reviewSummary(score, total, down),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: LtaSpace.s5),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                height: LtaSize.minTap,
                child: FilledButton(
                  onPressed: () => context.go(homeLocation),
                  child: Text(l.resultBackHome),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final q = _q;
    final checked = _checked.contains(q.id);
    final response = _response(q);
    final note = _note(l, q);
    final source = _items[_index].$2;
    final canReread = source != null &&
        q.sectionRef != null &&
        widget.content.lessons.containsKey(source);

    ExplanationPanel panel([ScrollController? controller]) => ExplanationPanel(
      key: ValueKey('explanation-${q.id}'),
      question: q,
      lang: lang,
      response: response,
      onNext: _next,
      onReread: canReread ? _reread : null,
      scrollController: controller,
      note: note,
    );

    return PopScope(
      canPop: _checked.isEmpty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: l.quizLeaveTooltip,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _checked.isEmpty ? _close() : _confirmLeave(),
          ),
          title: Text(
            l.quizProgress(_index + 1, total),
            style: theme.textTheme.titleMedium,
          ),
          actions: [
            LangToggle(
              lang: lang,
              onChanged: (v) => ref.read(contentLangProvider.notifier).set(v),
            ),
            const SizedBox(width: LtaSpace.s1),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(LtaSize.quizProgress),
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: (_index + (checked ? 1 : 0)) / total,
                minHeight: LtaSize.quizProgress,
                color: c.accent,
                backgroundColor: c.line,
              ),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= LtaBreakpoint.rail;
            final maxWidth = wide ? LtaSize.quizCardWide : LtaSize.quizCardMedium;
            final content = SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                LtaSpace.contentMobile,
                LtaSpace.s5,
                LtaSpace.contentMobile,
                checked && !wide
                    ? box.maxHeight * LtaSize.explanationSheet
                    : LtaSpace.s5,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_eyebrow(l, lang), style: t.eyebrow),
                      const SizedBox(height: LtaSpace.s3),
                      QuestionView(
                        key: ValueKey('question-${q.id}'),
                        question: q,
                        lang: lang,
                        response: response,
                        checked: checked,
                        onChanged: (v) => setState(() => _responses[q.id] = v),
                        contextExpanded: _contextExpanded,
                        onContextToggle: () =>
                            setState(() => _contextExpanded = !_contextExpanded),
                      ),
                      if (wide && checked) ...[
                        const SizedBox(height: LtaSpace.s5),
                        Card(margin: EdgeInsets.zero, child: panel()),
                      ],
                    ],
                  ),
                ),
              ),
            );
            if (wide || !checked) return content;
            return Stack(
              children: [
                Positioned.fill(child: content),
                ExplanationSheet(key: ValueKey('sheet-${q.id}'), builder: panel),
              ],
            );
          },
        ),
        bottomNavigationBar: checked
            ? null
            : BottomActionBar(
                primary: FilledButton(
                  onPressed: canCheck(q, response) ? _check : null,
                  child: Text(l.quizCheck),
                ),
              ),
      ),
    );
  }
}
