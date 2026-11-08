// Module quiz (`/module/:track/:moduleId/quiz`) — S4 in mode `module`
// (docs/05 S4, docs/07 §5.5): 12–15 questions drawn from the module's lesson
// quizzes, graded like a lesson quiz; wrong answers go to review. Its result
// (`/module/:track/:moduleId/result/:attemptId`) is S6 with a table by
// lesson; ≥ 70% → "Module ✓" on S2, lesson progress untouched.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/exam_repository.dart';
import '../../progress/module_quiz_sampler.dart';
import '../../progress/quiz_repository.dart';
import '../../shared/empty_state.dart';
import 'quiz_screen.dart';
import 'result_screen.dart';

class ModuleQuizScreen extends ConsumerWidget {
  const ModuleQuizScreen({super.key, required this.moduleKey});

  /// `track/module`.
  final String moduleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return ref.watch(contentProvider).when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => QuizMessage(text: l.contentLoadFailed),
      data: (c) {
        final module = c.module(moduleKey);
        if (module == null) return QuizMessage(text: l.resultNotFound);
        final lessonOf = ModuleQuizSampler.lessonOfQuestion(c, module);
        if (lessonOf.isEmpty) return QuizMessage(text: l.moduleQuizNone);
        return QuizSession(
          key: ValueKey(moduleKey),
          bank: {
            for (final quiz in ModuleQuizSampler.quizzesOf(c, module))
              for (final q in quiz.questions) q.id: q,
          },
          start: () => ref.read(examRepositoryProvider).startModule(c, module),
          sourceOf: (id) => lessonOf[id],
          finish: (context, ref, attempt, score, total) async {
            await ref
                .read(quizRepositoryProvider)
                .finish(attempt.id, score: score, total: total);
            if (context.mounted) {
              context.pushReplacement(moduleResultLocation(moduleKey, attempt.id));
            }
          },
        );
      },
    );
  }
}

class ModuleResultScreen extends ConsumerWidget {
  const ModuleResultScreen({
    super.key,
    required this.moduleKey,
    required this.attemptId,
  });

  final String moduleKey;
  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<LtaColors>()!;
    final content = ref.watch(contentProvider);
    final attempt = ref.watch(quizAttemptProvider(attemptId));
    Widget scaffold(Widget body) => Scaffold(appBar: AppBar(), body: body);
    if (content.hasError || attempt.hasError) {
      return scaffold(EmptyState(body: l.contentLoadFailed));
    }
    if (!content.hasValue || !attempt.hasValue) {
      return scaffold(const Center(child: CircularProgressIndicator()));
    }
    final c = content.value!;
    final module = c.module(moduleKey);
    final a = attempt.value;
    if (module == null ||
        a == null ||
        a.kind != QuizKind.module ||
        a.refId != moduleKey ||
        a.score == null) {
      return scaffold(
        Padding(
          padding: const EdgeInsets.all(LtaSpace.contentMobile),
          child: EmptyState(body: l.resultNotFound),
        ),
      );
    }
    final lang = effectiveLang(ref, context);
    final lessonOf = ModuleQuizSampler.lessonOfQuestion(c, module);
    final bank = {
      for (final quiz in ModuleQuizSampler.quizzesOf(c, module))
        for (final q in quiz.questions) q.id: q,
    };
    final score = a.score!;
    final total = a.total ?? a.questionIds.length;
    final passed = total > 0 && score / total >= ModuleQuizSampler.passRatio;
    final byLesson = <String, (int, int)>{};
    final wrong = <(int, Question, List<String>)>[];
    for (final (i, id) in a.questionIds.indexed) {
      final lesson = lessonOf[id];
      final answer = a.answers[id];
      final ok = answer?.correct ?? false;
      if (lesson != null) {
        final (r, n) = byLesson[lesson] ?? (0, 0);
        byLesson[lesson] = (r + (ok ? 1 : 0), n + 1);
      }
      if (!ok && bank[id] != null && answer != null) {
        wrong.add((i + 1, bank[id]!, answer.answer));
      }
    }
    final order = [
      for (final r in module.lessons)
        if (byLesson.containsKey(r.id)) r.id,
    ];

    Widget button(Widget child) => SizedBox(height: LtaSize.minTouch, child: child);

    final children = <Widget>[
      Text(
        passed ? l.resultPassed(score, total) : l.resultNotPassed(score, total),
        style: theme.textTheme.headlineMedium,
      ),
      const SizedBox(height: LtaSpace.s2),
      Text(
        module.title.of(lang),
        style: theme.textTheme.bodyLarge!.copyWith(color: colors.ink2),
      ),
      const SizedBox(height: LtaSpace.s6),
      Text(l.moduleResultByLesson, style: theme.textTheme.titleLarge),
      const SizedBox(height: LtaSpace.s2),
      for (final id in order)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: LtaSize.minTap),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c.lessonTitle(id)?.of(lang) ?? id,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: LtaSpace.s2),
              Text(
                l.pathCount(byLesson[id]!.$1, byLesson[id]!.$2),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      const SizedBox(height: LtaSpace.s6),
      if (wrong.isEmpty)
        Text(l.resultNoWrong, style: theme.textTheme.bodyMedium)
      else ...[
        Text(l.resultWrongHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: LtaSpace.s3),
        for (final (n, q, chosen) in wrong) ...[
          QuestionRecap(
            number: n,
            question: q,
            chosen: chosen,
            lang: lang,
            onReread: q.sectionRef == null || lessonOf[q.id] == null
                ? null
                : () => context.push(
                    lessonLocation(lessonOf[q.id]!, section: q.sectionRef),
                  ),
          ),
          const SizedBox(height: LtaSpace.s3),
        ],
        Text(
          l.resultReviewTomorrow(wrong.length),
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: LtaSpace.s6),
      if (!passed) ...[
        button(
          FilledButton(
            onPressed: () => context.pushReplacement(moduleQuizLocation(moduleKey)),
            child: Text(l.lessonRetakeQuiz),
          ),
        ),
        const SizedBox(height: LtaSpace.s2),
      ],
      button(
        passed
            ? FilledButton(
                onPressed: () => context.go(homeLocation),
                child: Text(l.resultBackHome),
              )
            : TextButton(
                onPressed: () => context.go(homeLocation),
                child: Text(l.resultBackHome),
              ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          LtaSpace.contentMobile,
          LtaSpace.s2,
          LtaSpace.contentMobile,
          LtaSpace.s6,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LtaSize.readingMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
