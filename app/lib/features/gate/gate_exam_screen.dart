// Gate exam (`/gate/:stage/exam/:attemptId`) — S4 in mode `gate` (docs/05
// S4): no explanation while answering (right/wrong only at the end),
// "Đánh dấu xem lại", ◀ ▶ between questions, pause for 24 hours. Answers are
// stored when leaving a question, so a paused or killed exam resumes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/exam_repository.dart';
import '../../progress/quiz_repository.dart';
import '../../shared/bottom_action_bar.dart';
import '../../shared/empty_state.dart';
import '../../shared/lang_toggle.dart';
import '../quiz/question_widgets/question_view.dart';
import '../quiz/quiz_grader.dart';
import 'gate_providers.dart';

class GateExamScreen extends ConsumerWidget {
  const GateExamScreen({super.key, required this.stage, required this.attemptId});

  final int stage;
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
    final sg = stageGate(content.value!, stage);
    final a = attempt.value;
    if (sg == null) return message(l.gateNone);
    if (a == null || a.kind != QuizKind.gate || a.refId != sg.$2.gate) {
      return message(l.resultNotFound);
    }
    final bank = {for (final q in sg.$2.questions) q.id: q};
    final questions = [for (final id in a.questionIds) ?bank[id]];
    if (questions.isEmpty) return message(l.gateNone);
    return _GateExam(
      key: ValueKey(a.id),
      stage: stage,
      attempt: a,
      questions: questions,
    );
  }
}

class _GateExam extends ConsumerStatefulWidget {
  const _GateExam({
    super.key,
    required this.stage,
    required this.attempt,
    required this.questions,
  });

  final int stage;
  final QuizAttemptRecord attempt;
  final List<Question> questions;

  @override
  ConsumerState<_GateExam> createState() => _GateExamState();
}

class _GateExamState extends ConsumerState<_GateExam> {
  late final ExamRepository _exam;
  late final QuizRepository _quiz;
  int _index = 0;
  final _responses = <String, List<String>>{};

  /// Responses already stored, to skip rewriting unchanged answers.
  final _stored = <String, List<String>>{};
  final _flags = <String>{};
  final _scroll = ScrollController();
  bool _contextExpanded = true;
  bool _leaving = false;
  Future<void> _pending = Future.value();

  Question get _q => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    _exam = ref.read(examRepositoryProvider);
    _quiz = ref.read(quizRepositoryProvider);
    for (final a in widget.attempt.answers.values) {
      if (a.answer.isEmpty) continue;
      _responses[a.questionId] = a.answer;
      _stored[a.questionId] = a.answer;
    }
    final next = widget.questions.indexWhere((q) => !_responses.containsKey(q.id));
    _index = next < 0 ? 0 : next;
    _exam.flagged(widget.attempt.id).then((f) {
      if (mounted) setState(() => _flags.addAll(f));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<String> _response(Question q) => _responses[q.id] ?? initialResponse(q);

  bool _answered(Question q) =>
      _responses.containsKey(q.id) && canCheck(q, _responses[q.id]!);

  /// Stores the current question's answer if it changed.
  void _save() {
    final q = _q;
    final r = _responses[q.id];
    if (r == null || !canCheck(q, r)) return;
    final prev = _stored[q.id];
    if (prev != null && prev.length == r.length && _sameList(prev, r)) return;
    _stored[q.id] = r;
    final id = widget.attempt.id;
    _pending = _pending.then(
      (_) => _quiz.recordAnswer(
        attemptId: id,
        kind: QuizKind.gate,
        questionId: q.id,
        answer: r,
        correct: gradeAnswer(q, r),
        sourceLesson: null,
      ),
    );
  }

  static bool _sameList(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _go(int index) {
    _save();
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _toggleFlag() {
    final q = _q;
    final on = !_flags.contains(q.id);
    setState(() => on ? _flags.add(q.id) : _flags.remove(q.id));
    _save();
    final id = widget.attempt.id;
    _pending = _pending.then((_) => _exam.setFlag(id, q.id, on));
  }

  Future<void> _pause() async {
    final l = L.of(context);
    final pause = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.gatePauseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.quizStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.gatePause),
          ),
        ],
      ),
    );
    if (pause != true || !mounted) return;
    _save();
    await _pending;
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(gateLocation(widget.stage));
      }
    });
  }

  Future<void> _submit() async {
    final l = L.of(context);
    _save();
    final unanswered = widget.questions.where((q) => !_answered(q)).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.gateSubmitConfirm(unanswered)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.gateSubmit),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _leaving = true);
    await _pending;
    await _exam.finishGate(widget.attempt.id, widget.stage);
    ref.invalidate(lastGateOutcomeProvider(widget.stage));
    ref.invalidate(quizAttemptProvider(widget.attempt.id));
    if (!mounted) return;
    context.pushReplacement(gateResultLocation(widget.stage, widget.attempt.id));
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
    final total = widget.questions.length;
    final q = _q;
    final last = _index == total - 1;
    final flagged = _flags.contains(q.id);

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: l.gatePause,
            icon: const Icon(Icons.close_rounded),
            onPressed: _pause,
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
                value: (_index + 1) / total,
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
            return SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(
                horizontal: LtaSpace.contentMobile,
                vertical: LtaSpace.s5,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? LtaSize.quizCardWide : LtaSize.quizCardMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_bloom(l, q.bloom).toUpperCase(), style: t.eyebrow),
                      const SizedBox(height: LtaSpace.s3),
                      QuestionView(
                        key: ValueKey('question-${q.id}'),
                        question: q,
                        lang: lang,
                        response: _response(q),
                        checked: false,
                        onChanged: (v) => setState(() => _responses[q.id] = v),
                        contextExpanded: _contextExpanded,
                        onContextToggle: () =>
                            setState(() => _contextExpanded = !_contextExpanded),
                      ),
                      const SizedBox(height: LtaSpace.s3),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: _toggleFlag,
                          icon: Icon(
                            flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                          ),
                          label: Text(flagged ? l.gateFlagged : l.gateFlag),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BottomActionBar(
          primary: Row(
            children: [
              if (_index > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _go(_index - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: Text(l.gatePrevious),
                  ),
                ),
                const SizedBox(width: LtaSpace.s3),
              ],
              Expanded(
                child: last
                    ? FilledButton(onPressed: _submit, child: Text(l.gateSubmit))
                    : FilledButton.icon(
                        onPressed: () => _go(_index + 1),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.chevron_right_rounded),
                        label: Text(l.quizNext),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
