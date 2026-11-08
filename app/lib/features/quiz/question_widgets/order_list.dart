// OrderList — docs/05 §6 / S4 `order`: `ReorderableListView` of the steps
// in JSON order, ⋮⋮ handle on the right, step number on the left updating as
// it moves, ▲▼ buttons per row. When wrong: "Bạn xếp" next to "Đúng".
import 'package:flutter/material.dart';

import '../../../app/theme/text.dart';
import '../../../app/theme/tokens.dart';
import '../../../content/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../quiz_grader.dart';
import 'quiz_text.dart';

class OrderList extends StatelessWidget {
  const OrderList({
    super.key,
    required this.question,
    required this.lang,
    required this.order,
    required this.checked,
    required this.correct,
    required this.onReorder,
  });

  final Question question;
  final ContentLang lang;

  /// Option ids in the learner's current order.
  final List<String> order;
  final bool checked;
  final bool correct;
  final ValueChanged<List<String>> onReorder;

  QuestionOption _option(String id) =>
      question.options.firstWhere((o) => o.id == id);

  void _move(int from, int to) {
    if (to < 0 || to >= order.length) return;
    final next = [...order];
    final id = next.removeAt(from);
    next.insert(to, id);
    onReorder(next);
  }

  @override
  Widget build(BuildContext context) {
    if (checked && !correct) return _Compare(question: question, lang: lang, yours: order);
    final l = L.of(context);
    final c = Theme.of(context).extension<LtaColors>()!;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: order.length,
      onReorderItem: _move,
      itemBuilder: (context, i) {
        final id = order[i];
        return Padding(
          key: ValueKey('order-$id'),
          padding: const EdgeInsets.only(bottom: LtaSpace.s2),
          child: _StepCard(
            number: i + 1,
            text: _option(id).text.of(lang),
            state: checked ? _StepState.correct : _StepState.idle,
            trailing: checked
                ? [Icon(Icons.check_rounded, color: c.correct, size: LtaSize.icon)]
                : [
                    IconButton(
                      key: ValueKey('order-up-$id'),
                      tooltip: l.quizMoveUp,
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      onPressed: i == 0 ? null : () => _move(i, i - 1),
                    ),
                    IconButton(
                      key: ValueKey('order-down-$id'),
                      tooltip: l.quizMoveDown,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onPressed: i == order.length - 1 ? null : () => _move(i, i + 1),
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.all(LtaSpace.s2),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: c.ink2,
                          size: LtaSize.icon,
                        ),
                      ),
                    ),
                  ],
          ),
        );
      },
    );
  }
}

enum _StepState { idle, correct, wrong }

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.number,
    required this.text,
    required this.state,
    this.trailing = const [],
    this.dense = false,
  });

  final int number;
  final String text;
  final _StepState state;
  final List<Widget> trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final (border, fill) = switch (state) {
      _StepState.idle => (c.line, c.surface),
      _StepState.correct => (c.correct, c.correctSoft),
      _StepState.wrong => (c.incorrect, c.incorrectSoft),
    };
    final style = dense ? theme.textTheme.bodyMedium! : t.quizOption;
    return Container(
      constraints: BoxConstraints(minHeight: dense ? LtaSize.minTap : LtaSize.minTouch),
      padding: const EdgeInsetsDirectional.only(
        start: LtaSpace.s3,
        top: LtaSpace.s2,
        bottom: LtaSpace.s2,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(LtaRadius.card),
        border: Border.all(color: border, width: LtaSize.emphasisBorder),
      ),
      child: Row(
        children: [
          Container(
            width: LtaSize.quizBadge,
            height: LtaSize.quizBadge,
            alignment: Alignment.center,
            decoration: ShapeDecoration(color: c.surface2, shape: const CircleBorder()),
            child: Text('$number', style: theme.textTheme.labelLarge!.copyWith(color: c.ink2)),
          ),
          const SizedBox(width: LtaSpace.s3),
          Expanded(child: QuizText(text, style: style)),
          if (trailing.isEmpty) const SizedBox(width: LtaSpace.s3),
          ...trailing,
        ],
      ),
    );
  }
}

/// Wrong order: "Bạn xếp" column next to "Đúng" (docs/05 S4).
class _Compare extends StatelessWidget {
  const _Compare({required this.question, required this.lang, required this.yours});

  final Question question;
  final ContentLang lang;
  final List<String> yours;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final t = Theme.of(context).extension<LtaText>()!;
    String text(String id) =>
        '${optionLetter(id)} · ${question.options.firstWhere((o) => o.id == id).text.of(lang)}';
    Widget column(String title, List<String> ids, {required bool mine}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.toUpperCase(), style: t.eyebrow),
        const SizedBox(height: LtaSpace.s2),
        for (final (i, id) in ids.indexed) ...[
          if (i > 0) const SizedBox(height: LtaSpace.s2),
          _StepCard(
            key: ValueKey('order-${mine ? 'yours' : 'answer'}-$id'),
            number: i + 1,
            text: text(id),
            dense: true,
            state: !mine || question.answer[i] == id
                ? _StepState.correct
                : _StepState.wrong,
          ),
        ],
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(l.quizOrderYours, yours, mine: true)),
        const SizedBox(width: LtaSpace.s3),
        Expanded(child: column(l.quizCorrect, question.answer, mine: false)),
      ],
    );
  }
}
