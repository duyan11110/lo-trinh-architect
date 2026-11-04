// S4 Quiz (`/learn/:lessonId/quiz`) — docs/05 S4, mode `lesson`. One
// question per screen: answer → "Kiểm tra" → right/wrong and why → next.
// Every checked answer is stored at once (quiz_answer; wrong → review_item,
// docs/07 §5.3) so an app kill resumes at the next question. [QuizSession]
// also runs mode `module` (module_quiz_screen.dart); `review` is
// review_session_screen.dart and `gate` gate_exam_screen.dart over the same
// question widgets.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/progress_repository.dart';
import '../../progress/quiz_repository.dart';
import '../../shared/bottom_action_bar.dart';
import '../../shared/lang_toggle.dart';
import 'explanation_panel.dart';
import 'question_widgets/question_view.dart';
import 'quiz_grader.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return ref
        .watch(contentProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => QuizMessage(
            text: l.contentLoadFailed,
            action: TextButton(
              onPressed: () => ref.invalidate(contentProvider),
              child: Text(l.contentRetry),
            ),
          ),
          data: (c) {
            final lesson = c.lessons[lessonId];
            if (lesson == null) return QuizMessage(text: l.lessonNotFound);
            final quiz = c.quizzes[lessonId];
            if (quiz == null || quiz.questions.isEmpty) {
              return QuizMessage(text: l.quizNone);
            }
            final ids = [for (final q in quiz.questions) q.id];
            return QuizSession(
              key: ValueKey(lessonId),
              bank: {for (final q in quiz.questions) q.id: q},
              start: () => ref
                  .read(quizRepositoryProvider)
                  .startOrResume(QuizKind.lesson, lesson.id, ids),
              sourceOf: (_) => lesson.id,
              finish: (context, ref, attempt, score, total) async {
                await ref
                    .read(quizRepositoryProvider)
                    .finish(attempt.id, score: score, total: total);
                await ref
                    .read(progressRepositoryProvider)
                    .recordQuizScore(
                      lesson.id,
                      ratio: score / total,
                      contentVersion: lesson.contentVersion,
                    );
                if (context.mounted) {
                  context.pushReplacement(
                    resultLocation(lesson.id, attempt.id),
                  );
                }
              },
            );
          },
        );
  }
}

class QuizMessage extends StatelessWidget {
  const QuizMessage({super.key, required this.text, this.action});

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

/// Finishes an attempt (store the score, route to the result).
typedef QuizFinish = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  QuizAttemptRecord attempt,
  int score,
  int total,
);

/// S4 modes `lesson` and `module`: the questions of the attempt returned by
/// [start], looked up in [bank] in the attempt's order.
class QuizSession extends ConsumerStatefulWidget {
  const QuizSession({
    super.key,
    required this.bank,
    required this.start,
    required this.sourceOf,
    required this.finish,
  });

  final Map<String, Question> bank;
  final Future<QuizAttemptRecord> Function() start;

  /// Lesson a question belongs to (review item source, "Đọc lại mục N").
  final String? Function(String questionId) sourceOf;
  final QuizFinish finish;

  @override
  ConsumerState<QuizSession> createState() => _QuizSessionState();
}

class _QuizSessionState extends ConsumerState<QuizSession> {
  late final QuizRepository _repo;
  QuizAttemptRecord? _attempt;
  List<Question> _questions = const [];
  int _index = 0;
  final _responses = <String, List<String>>{};
  final _checked = <String>{};
  final _results = <String, bool>{};
  final _scroll = ScrollController();
  bool _contextExpanded = true;
  bool _finishing = false;
  Future<void> _pending = Future.value();

  Question get _q => _questions[_index];

  @override
  void initState() {
    super.initState();
    _repo = ref.read(quizRepositoryProvider);
    _start();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final attempt = await widget.start();
    if (!mounted) return;
    setState(() {
      _attempt = attempt;
      _questions = [for (final id in attempt.questionIds) ?widget.bank[id]];
      for (final a in attempt.answers.values) {
        _responses[a.questionId] = a.answer;
        _checked.add(a.questionId);
        _results[a.questionId] = a.correct;
      }
      final next = _questions.indexWhere((q) => !_checked.contains(q.id));
      _index = next < 0 ? _questions.length - 1 : next;
    });
  }

  List<String> _response(Question q) => _responses[q.id] ?? initialResponse(q);

  void _check() {
    final q = _q;
    final response = _response(q);
    final correct = gradeAnswer(q, response);
    setState(() {
      _responses[q.id] = response;
      _checked.add(q.id);
      _results[q.id] = correct;
    });
    final attempt = _attempt!;
    _pending = _pending.then(
      (_) => _repo.recordAnswer(
        attemptId: attempt.id,
        kind: attempt.kind,
        questionId: q.id,
        answer: response,
        correct: correct,
        sourceLesson: widget.sourceOf(q.id),
      ),
    );
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    if (_finishing) return;
    _finishing = true;
    final attempt = _attempt!;
    final score = [
      for (final q in _questions)
        if (_results[q.id] ?? false) q,
    ].length;
    await _pending;
    if (!mounted) return;
    await widget.finish(context, ref, attempt, score, _questions.length);
  }

  void _reread() {
    final source = widget.sourceOf(_q.id);
    if (source == null) return;
    context.push(lessonLocation(source, section: _q.sectionRef));
  }

  /// docs/05 S4: leaving after ≥ 1 answer asks first; answers stay in
  /// review, the attempt closes without a score.
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
    await _repo.abandon(_attempt!.id);
    if (!mounted) return;
    setState(() => _finishing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _bloom(L l, Bloom b) => switch (b) {
    Bloom.remember => l.bloomRemember,
    Bloom.understand => l.bloomUnderstand,
    Bloom.apply => l.bloomApply,
    Bloom.analyze => l.bloomAnalyze,
    Bloom.evaluate => l.bloomEvaluate,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final lang = effectiveLang(ref, context);
    if (_attempt == null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: _attempt == null
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Text(l.quizNone)),
      );
    }
    final total = _questions.length;
    final q = _q;
    final checked = _checked.contains(q.id);
    final response = _response(q);
    final answered = _checked.length;

    final eyebrow = [
      _bloom(l, q.bloom),
      if (q.sectionRef != null) l.quizSection(q.sectionRef!),
    ].join(' · ').toUpperCase();

    return PopScope(
      canPop: answered == 0 || _finishing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: l.quizLeaveTooltip,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
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
            final maxWidth = wide
                ? LtaSize.quizCardWide
                : LtaSize.quizCardMedium;
            final panel = checked
                ? ExplanationPanel(
                    key: ValueKey('explanation-${q.id}'),
                    question: q,
                    lang: lang,
                    response: response,
                    onNext: _next,
                    onReread: q.sectionRef == null ? null : _reread,
                  )
                : null;
            final content = SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                LtaSpace.contentMobile,
                LtaSpace.s5,
                LtaSpace.contentMobile,
                // Mobile: room to scroll the options above the sheet.
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
                      Text(eyebrow, style: t.eyebrow),
                      const SizedBox(height: LtaSpace.s3),
                      QuestionView(
                        key: ValueKey('question-${q.id}'),
                        question: q,
                        lang: lang,
                        response: response,
                        checked: checked,
                        onChanged: (v) => setState(() => _responses[q.id] = v),
                        contextExpanded: _contextExpanded,
                        onContextToggle: () => setState(
                          () => _contextExpanded = !_contextExpanded,
                        ),
                      ),
                      if (wide && panel != null) ...[
                        const SizedBox(height: LtaSpace.s5),
                        Card(margin: EdgeInsets.zero, child: panel),
                      ],
                    ],
                  ),
                ),
              ),
            );
            if (wide || panel == null) return content;
            return Stack(
              children: [
                Positioned.fill(child: content),
                ExplanationSheet(
                  key: ValueKey('sheet-${q.id}'),
                  builder: (controller) => ExplanationPanel(
                    key: ValueKey('explanation-${q.id}'),
                    question: q,
                    lang: lang,
                    response: response,
                    onNext: _next,
                    onReread: q.sectionRef == null ? null : _reread,
                    scrollController: controller,
                  ),
                ),
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

/// Mobile ExplanationPanel: slides up (220 ms easeOutCubic, docs/05 §5.5),
/// opens at 50% of the screen and can be dragged up.
class ExplanationSheet extends StatelessWidget {
  const ExplanationSheet({super.key, required this.builder});

  final Widget Function(ScrollController controller) builder;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: reduce ? Duration.zero : LtaMotion.explanation,
      curve: LtaMotion.explanationCurve,
      builder: (context, v, child) =>
          FractionalTranslation(translation: Offset(0, v), child: child),
      child: DraggableScrollableSheet(
        initialChildSize: LtaSize.explanationSheet,
        minChildSize: LtaSize.explanationSheetMin,
        maxChildSize: LtaSize.explanationSheetMax,
        builder: (context, controller) => DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(LtaRadius.card),
            ),
            boxShadow: LtaElevation.soft(c),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: builder(controller),
          ),
        ),
      ),
    );
  }
}
