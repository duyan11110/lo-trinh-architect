// S6 Kết quả quiz (`/learn/:lessonId/result/:attemptId`) — docs/05 S6.
// Score as text, the missed questions (QuestionRecap) with "Đọc lại mục N",
// the review note, SkillDelta, then the next step — "Quay lại: <bài>" first
// when this lesson was opened from S5 "Học bài trước". No score animation.
// Module and gate results (M6) extend this screen later.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/lesson_status.dart';
import '../../progress/plan_provider.dart';
import '../../progress/progress_repository.dart';
import '../../progress/quiz_repository.dart';
import '../lesson/prereq_dialog.dart';
import 'question_widgets/quiz_text.dart';
import 'quiz_grader.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.lessonId, required this.attemptId});

  final String lessonId;
  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final content = ref.watch(contentProvider);
    final attempt = ref.watch(quizAttemptProvider(attemptId));
    if (content.hasError || attempt.hasError) {
      return _scaffold(Center(child: Text(l.contentLoadFailed)));
    }
    if (!content.hasValue || !attempt.hasValue) {
      return _scaffold(const Center(child: CircularProgressIndicator()));
    }
    final c = content.value!;
    final a = attempt.value;
    final lesson = c.lessons[lessonId];
    if (a == null || a.refId != lessonId || a.score == null || lesson == null) {
      return _scaffold(Center(child: Text(l.resultNotFound)));
    }
    return _ResultView(content: c, lesson: lesson, attempt: a);
  }

  Widget _scaffold(Widget body) => Scaffold(appBar: AppBar(), body: body);
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.content, required this.lesson, required this.attempt});

  final Content content;
  final Lesson lesson;
  final QuizAttemptRecord attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final lang = effectiveLang(ref, context);
    final score = attempt.score!;
    final total = attempt.total!;
    final passed = total > 0 && score / total >= lessonPassRatio;
    final questions = {
      for (final q in content.quizzes[lesson.id]?.questions ?? const <Question>[]) q.id: q,
    };
    final wrong = [
      for (final (i, id) in attempt.questionIds.indexed)
        if (attempt.answers[id]?.correct == false && questions[id] != null)
          (i + 1, questions[id]!, attempt.answers[id]!.answer),
    ];
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    final next = ref.watch(learningPlanProvider).value?.next;
    final nextId = next != null && next.id != lesson.id ? next.id : null;
    final back = passed
        ? prereqReturnTarget(content, ref.watch(prereqReturnProvider), lesson.id)
        : null;

    void goHome() => context.go(homeLocation);
    void reread() => context.canPop() ? context.pop() : context.go(lessonLocation(lesson.id));

    final skills = [
      for (final id in lesson.skills)
        (content.skills.where((s) => s.id == id).firstOrNull, id),
    ];

    final children = <Widget>[
      Text(
        passed ? l.resultPassed(score, total) : l.resultNotPassed(score, total),
        style: theme.textTheme.headlineMedium,
      ),
      const SizedBox(height: LtaSpace.s2),
      Text(lesson.title.of(lang), style: theme.textTheme.bodyLarge!.copyWith(color: c.ink2)),
      const SizedBox(height: LtaSpace.s6),
      if (wrong.isEmpty)
        Text(l.resultNoWrong, style: theme.textTheme.bodyMedium)
      else ...[
        Text(l.resultWrongHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: LtaSpace.s3),
        for (final (n, q, answer) in wrong) ...[
          QuestionRecap(
            number: n,
            question: q,
            chosen: answer,
            lang: lang,
            onReread: q.sectionRef == null
                ? null
                : () => context.push(lessonLocation(lesson.id, section: q.sectionRef)),
          ),
          const SizedBox(height: LtaSpace.s3),
        ],
        Text(l.resultReviewTomorrow(wrong.length), style: theme.textTheme.bodySmall),
      ],
      if (passed && skills.isNotEmpty) ...[
        const SizedBox(height: LtaSpace.s6),
        Text(l.resultSkills, style: theme.textTheme.titleLarge),
        const SizedBox(height: LtaSpace.s2),
        for (final (skill, id) in skills)
          SkillDelta(
            title: skill?.title.of(lang) ?? id,
            isNew: !(skill?.lessons ?? const <String>[]).any(
              (other) => other != lesson.id && progress[other]?.status == LessonStatus.passed,
            ),
          ),
      ],
      const SizedBox(height: LtaSpace.s6),
      if (back != null) ...[
        _button(FilledButton(
          onPressed: () {
            ref.read(prereqReturnProvider.notifier).set(null);
            context.go(lessonLocation(back.id));
          },
          child: Text(
            l.prereqReturn(back.title.of(lang)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),
        const SizedBox(height: LtaSpace.s2),
      ],
      if (passed && nextId != null)
        _button(back != null
            ? OutlinedButton(
                onPressed: () => context.go(lessonLocation(nextId)),
                child: Text(l.lessonNextLesson),
              )
            : FilledButton.icon(
          onPressed: () => context.go(lessonLocation(nextId)),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(l.lessonNextLesson),
        ))
      else if (!passed) ...[
        _button(FilledButton(onPressed: reread, child: Text(l.resultRereadLesson))),
        const SizedBox(height: LtaSpace.s2),
        _button(OutlinedButton(
          onPressed: () => context.pushReplacement(quizLocation(lesson.id)),
          child: Text(l.lessonRetakeQuiz),
        )),
      ],
      const SizedBox(height: LtaSpace.s2),
      _button(
        passed && nextId == null
            ? FilledButton(onPressed: goHome, child: Text(l.resultBackHome))
            : TextButton(onPressed: goHome, child: Text(l.resultBackHome)),
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
        child: SafeArea(
          top: false,
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
      ),
    );
  }

  Widget _button(Widget child) => SizedBox(height: LtaSize.minTouch, child: child);
}

/// QuestionRecap — docs/05 §6: the question, what was chosen, the answer,
/// [Đọc lại mục N].
class QuestionRecap extends StatelessWidget {
  const QuestionRecap({
    super.key,
    required this.number,
    required this.question,
    required this.chosen,
    required this.lang,
    this.onReread,
  });

  final int number;
  final Question question;
  final List<String> chosen;
  final ContentLang lang;
  final VoidCallback? onReread;

  String _describe(List<String> ids) {
    final q = question;
    if (q.type == QuestionType.fill) return ids.join(' · ');
    if (q.type == QuestionType.order || q.type == QuestionType.multi) {
      return answerLabel(q, ids);
    }
    final o = q.options.where((o) => o.id == ids.firstOrNull).firstOrNull;
    return o == null ? answerLabel(q, ids) : '${optionLetter(o.id)} · ${o.text.of(lang)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final l = L.of(context);
    final body = theme.textTheme.bodyMedium!;
    Widget line(String label, String value, Color color) => Padding(
      padding: const EdgeInsets.only(top: LtaSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.eyebrow.copyWith(color: color)),
          QuizText(value, style: body),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(LtaSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LtaRadius.card),
        border: Border.all(color: c.line, width: LtaSize.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuizText('$number · ${question.question.of(lang)}', style: body.copyWith(fontWeight: FontWeight.w500)),
          line(l.quizYouChose, _describe(chosen), c.incorrect),
          line(l.resultAnswer, _describe(question.answer), c.correct),
          if (onReread != null && question.sectionRef != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onReread,
                child: Text(l.quizReread(question.sectionRef!)),
              ),
            ),
        ],
      ),
    );
  }
}

/// SkillDelta — docs/05 S6: skill name + ▲ or "mới"; no skill score in V1.
class SkillDelta extends StatelessWidget {
  const SkillDelta({super.key, required this.title, required this.isNew});

  final String title;

  /// No other passed lesson teaches this skill yet.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final l = L.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LtaSize.minTap),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: LtaSpace.s2),
          if (isNew)
            Text(l.resultSkillNew.toUpperCase(), style: t.eyebrow.copyWith(color: c.correct))
          else
            Icon(
              Icons.arrow_upward_rounded,
              color: c.correct,
              size: LtaSize.icon,
              semanticLabel: l.resultSkillUp,
            ),
        ],
      ),
    );
  }
}
