// ExplanationPanel — docs/05 S4 "Sau khi bấm Kiểm tra" and §6: result
// line, `explanation.correct`, the explanation of each option the learner
// chose wrongly, the others behind "Xem giải thích khác ▾" (scenario: shown
// as "Khi nào phương án X lại đúng"), then [Đọc lại mục N] [Tiếp →].
import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import 'question_widgets/quiz_text.dart';
import 'quiz_grader.dart';

class ExplanationPanel extends StatelessWidget {
  const ExplanationPanel({
    super.key,
    required this.question,
    required this.lang,
    required this.response,
    required this.onNext,
    this.onReread,
    this.scrollController,
    this.note,
  });

  final Question question;
  final ContentLang lang;
  final List<String> response;
  final VoidCallback onNext;

  /// Opens the lesson at `section_ref`; `null` hides the button.
  final VoidCallback? onReread;

  /// From the mobile `DraggableScrollableSheet`.
  final ScrollController? scrollController;

  /// Small line above the actions (review mode: "Bậc 1 → 2 · …").
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final l = L.of(context);
    final q = question;
    final correct = gradeAnswer(q, response);
    final expl = q.explanation(lang);
    final body = theme.textTheme.bodyMedium!;
    final heading = theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700);

    final chosenWrong = [
      for (final o in q.options)
        if (response.contains(o.id) && !q.answer.contains(o.id) && expl[o.id] != null)
          o.id,
    ];
    final others = [
      for (final o in q.options)
        if (!chosenWrong.contains(o.id) && !q.answer.contains(o.id) && expl[o.id] != null)
          o.id,
    ];

    Widget block(String title, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: c.line, height: LtaSpace.s5),
        Text(title, style: heading),
        const SizedBox(height: LtaSpace.s1),
        QuizText(text, style: body),
      ],
    );

    final resultText = correct
        ? l.quizCorrect
        : l.quizIncorrect(
            q.type == QuestionType.fill ? q.answer.first : answerLabel(q, q.answer),
          );
    final children = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: correct ? c.correct : c.incorrect,
            size: LtaSize.icon,
          ),
          const SizedBox(width: LtaSpace.s2),
          Expanded(
            child: Text(
              resultText,
              style: theme.textTheme.titleMedium!.copyWith(
                color: correct ? c.correct : c.incorrect,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: LtaSpace.s2),
      if (expl['correct'] != null) QuizText(expl['correct']!, style: body),
      for (final id in chosenWrong)
        block(l.quizWhyNot(optionLetter(id)), expl[id]!),
      if (others.isNotEmpty && q.type == QuestionType.scenario)
        for (final id in others)
          block(l.quizWhenRight(optionLetter(id)), expl[id]!),
      if (others.isNotEmpty && q.type != QuestionType.scenario) ...[
        Divider(color: c.line, height: LtaSpace.s5),
        Theme(
          data: theme.copyWith(dividerColor: c.surface),
          child: ExpansionTile(
            key: ValueKey('others-${q.id}'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            iconColor: c.ink2,
            collapsedIconColor: c.ink2,
            title: Text(l.quizOtherExplanations, style: heading.copyWith(color: c.accent)),
            children: [
              for (final (i, id) in others.indexed) ...[
                if (i > 0) const SizedBox(height: LtaSpace.s3),
                Text(l.quizWhyNot(optionLetter(id)), style: heading),
                const SizedBox(height: LtaSpace.s1),
                QuizText(expl[id]!, style: body),
              ],
            ],
          ),
        ),
      ],
      if (note != null) ...[
        const SizedBox(height: LtaSpace.s4),
        Text(note!, style: body.copyWith(color: c.ink2)),
      ],
      const SizedBox(height: LtaSpace.s4),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: LtaSpace.s2,
        runSpacing: LtaSpace.s2,
        children: [
          if (onReread != null && q.sectionRef != null)
            SizedBox(
              height: LtaSize.minTap,
              child: OutlinedButton(
                onPressed: onReread,
                child: Text(l.quizReread(q.sectionRef!)),
              ),
            ),
          SizedBox(
            height: LtaSize.minTap,
            child: FilledButton.icon(
              onPressed: onNext,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l.quizNext),
            ),
          ),
        ],
      ),
    ];

    // Not a lazy ListView: the actions at the end must always be built.
    return SingleChildScrollView(
      controller: scrollController,
      physics: scrollController == null ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(
        LtaSpace.contentMobile,
        LtaSpace.s4,
        LtaSpace.contentMobile,
        LtaSpace.s5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
