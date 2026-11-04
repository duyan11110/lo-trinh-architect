// The body of one question on S4 — docs/05 S4 "Tương tác theo loại câu":
// single / multi / truefalse / scenario as QuizOption cards, order as
// OrderList, fill as an inline FillField. Stateless over the response: the
// screen owns it, keyed by option id, so switching VI/EN keeps the choice.
import 'package:flutter/material.dart';

import '../../../app/theme/text.dart';
import '../../../app/theme/tokens.dart';
import '../../../content/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../quiz_grader.dart';
import 'fill_field.dart';
import 'order_list.dart';
import 'quiz_option.dart';
import 'quiz_text.dart';

class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.lang,
    required this.response,
    required this.onChanged,
    required this.checked,
    this.contextExpanded = true,
    this.onContextToggle,
  });

  final Question question;
  final ContentLang lang;
  final List<String> response;
  final ValueChanged<List<String>> onChanged;

  /// After "Kiểm tra": read-only, shows right/wrong.
  final bool checked;

  /// `ContextCard` state, remembered for the session (docs/05 §6).
  final bool contextExpanded;
  final VoidCallback? onContextToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.extension<LtaText>()!;
    final c = theme.extension<LtaColors>()!;
    final l = L.of(context);
    final q = question;
    final correct = checked && gradeAnswer(q, response);
    final fill = q.type == QuestionType.fill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (q.context != null) ...[
          ContextCard(
            text: q.context!.of(lang),
            expanded: contextExpanded,
            onToggle: onContextToggle,
          ),
          const SizedBox(height: LtaSpace.s4),
        ],
        QuizText(
          q.question.of(lang),
          style: t.quizQuestion,
          blank: fill
              ? (inCode) => FillField(
                  key: ValueKey('fill-${q.id}'),
                  value: response.isEmpty ? '' : response.first,
                  mono: inCode,
                  checked: checked,
                  correct: correct,
                  onChanged: (v) => onChanged([v]),
                )
              : null,
        ),
        if (fill && !fillBlank.hasMatch(q.question.of(lang))) ...[
          // No blank in the text: the field goes under the question.
          const SizedBox(height: LtaSpace.s3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FillField(
              key: ValueKey('fill-${q.id}'),
              value: response.isEmpty ? '' : response.first,
              mono: true,
              checked: checked,
              correct: correct,
              onChanged: (v) => onChanged([v]),
            ),
          ),
        ],
        if (q.type == QuestionType.multi) ...[
          const SizedBox(height: LtaSpace.s2),
          Text(l.quizSelectAll, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: LtaSpace.s5),
        ...switch (q.type) {
          QuestionType.fill => [
            if (checked && !correct)
              Text(
                l.quizAccepted(q.answer.join(' · ')),
                style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
              ),
          ],
          QuestionType.order => [
            OrderList(
              question: q,
              lang: lang,
              order: response,
              checked: checked,
              correct: correct,
              onReorder: onChanged,
            ),
          ],
          QuestionType.truefalse => _trueFalse(context, correct),
          _ => _options(context, q.options, correct),
        },
      ],
    );
  }

  List<Widget> _options(
    BuildContext context,
    List<QuestionOption> options,
    bool correct, {
    String Function(QuestionOption o)? textOf,
  }) {
    final l = L.of(context);
    final q = question;
    final multi = q.type == QuestionType.multi;
    return [
      for (final (i, o) in options.indexed) ...[
        if (i > 0) const SizedBox(height: LtaSpace.s2),
        QuizOption(
          key: ValueKey('option-${o.id}'),
          letter: optionLetter(o.id),
          text: textOf?.call(o) ?? o.text.of(lang),
          kind: multi ? QuizOptionKind.checkbox : QuizOptionKind.radio,
          state: _state(o.id),
          chosen: response.contains(o.id),
          note: checked && !correct && response.contains(o.id) ? l.quizYouChose : null,
          onTap: checked ? null : () => _toggle(o.id),
        ),
      ],
    ];
  }

  /// docs/05 S4: two rows by `polarity` — "Đúng, vì…" then "Sai, vì…" —
  /// row label bold, the reason in plain text. Options without polarity
  /// follow, unlabelled.
  List<Widget> _trueFalse(BuildContext context, bool correct) {
    final theme = Theme.of(context);
    final l = L.of(context);
    final groups = [
      (l.quizTrueBecause, question.options.where((o) => polarityOf(o) == true).toList()),
      (l.quizFalseBecause, question.options.where((o) => polarityOf(o) == false).toList()),
      (null, question.options.where((o) => polarityOf(o) == null).toList()),
    ];
    final out = <Widget>[];
    for (final (label, options) in groups) {
      if (options.isEmpty) continue;
      if (out.isNotEmpty) out.add(const SizedBox(height: LtaSpace.s4));
      if (label != null) {
        out
          ..add(
            Text(
              label,
              key: ValueKey('tf-${polarityOf(options.first)}'),
              style: theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
          )
          ..add(const SizedBox(height: LtaSpace.s2));
      }
      out.addAll(
        _options(
          context,
          options,
          correct,
          textOf: (o) => stripPolarityPrefix(o.text.of(lang)),
        ),
      );
    }
    return out;
  }

  QuizOptionState _state(String id) {
    final chosen = response.contains(id);
    if (!checked) return chosen ? QuizOptionState.selected : QuizOptionState.idle;
    if (question.answer.contains(id)) return QuizOptionState.correct;
    return chosen ? QuizOptionState.wrong : QuizOptionState.dimmed;
  }

  void _toggle(String id) {
    if (question.type == QuestionType.multi) {
      final next = [...response];
      next.contains(id) ? next.remove(id) : next.add(id);
      // Keep JSON option order so the stored answer is stable.
      final order = [for (final o in question.options) o.id];
      next.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      onChanged(next);
    } else {
      onChanged([id]);
    }
  }
}

final _polarityPrefix = RegExp(
  r'^\s*(Đúng|Sai|True|False)\s*,\s*(?:vì|because)\s*(?:…|\.\.\.)?\s*',
  caseSensitive: false,
);

/// The option's `polarity`; content without the field (older banks, the
/// sample) falls back to the "Đúng/True, …" / "Sai/False, …" prefix.
bool? polarityOf(QuestionOption o) {
  if (o.polarity != null) return o.polarity;
  final m = _polarityPrefix.firstMatch(o.text.en) ?? _polarityPrefix.firstMatch(o.text.vi);
  if (m == null) return null;
  final w = m[1]!.toLowerCase();
  return w == 'đúng' || w == 'true';
}

/// `truefalse` options begin "Đúng, vì …"/"Sai, vì …" (EN "True, because …"/
/// "False, because …", docs/01 §6); the row label already says it, so the
/// card shows the reason only. Text without the prefix is left as is.
String stripPolarityPrefix(String text) {
  final m = _polarityPrefix.firstMatch(text);
  if (m == null || m.end >= text.length) return text;
  return text.substring(m.end);
}

/// ContextCard — docs/05 §6: the `scenario` context, collapsible, open by
/// default; the state is remembered for the session.
class ContextCard extends StatelessWidget {
  const ContextCard({
    super.key,
    required this.text,
    required this.expanded,
    this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final l = L.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(LtaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              borderRadius: BorderRadius.circular(LtaRadius.card),
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: LtaSize.minTap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LtaSpace.s4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.quizContext.toUpperCase(), style: t.eyebrow),
                      ),
                      Icon(
                        expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: c.ink2,
                        size: LtaSize.icon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LtaSpace.s4,
                0,
                LtaSpace.s4,
                LtaSpace.s4,
              ),
              child: QuizText(text, style: theme.textTheme.bodyMedium!),
            ),
        ],
      ),
    );
  }
}
