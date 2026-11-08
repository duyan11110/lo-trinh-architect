// Quiz strings (question, option, explanation) are plain text with inline
// code in backticks. Renders the code parts in mono on `surface2`, and can
// swap the first `fill` blank for a widget (docs/05 S4: `FillField` inline,
// mono when the blank sits inside code).
import 'package:flutter/material.dart';

import '../../../app/theme/text.dart';
import '../../../app/theme/tokens.dart';
import '../quiz_grader.dart';

/// Builds the blank widget; [inCode] is true when the blank is inside
/// backticks.
typedef BlankBuilder = Widget Function(bool inCode);

List<InlineSpan> quizSpans(
  BuildContext context,
  String text, {
  required TextStyle style,
  BlankBuilder? blank,
}) {
  final theme = Theme.of(context);
  final c = theme.extension<LtaColors>()!;
  final t = theme.extension<LtaText>()!;
  final code = t.code.copyWith(
    fontSize: style.fontSize,
    color: c.ink,
    backgroundColor: c.surface2,
  );
  final spans = <InlineSpan>[];
  var blankDone = blank == null;
  final parts = text.split('`');
  // An unmatched backtick stays literal: fold the dangling part back.
  if (parts.length.isEven) {
    final tail = parts.removeLast();
    parts[parts.length - 1] = '${parts.last}`$tail';
  }
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty) continue;
    final inCode = i.isOdd;
    final s = inCode ? code : style;
    final m = blankDone ? null : fillBlank.firstMatch(part);
    if (m == null) {
      spans.add(TextSpan(text: part, style: s));
      continue;
    }
    blankDone = true;
    if (m.start > 0) spans.add(TextSpan(text: part.substring(0, m.start), style: s));
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: blank!(inCode),
      ),
    );
    if (m.end < part.length) spans.add(TextSpan(text: part.substring(m.end), style: s));
  }
  return spans;
}

class QuizText extends StatelessWidget {
  const QuizText(this.text, {super.key, required this.style, this.blank});

  final String text;
  final TextStyle style;
  final BlankBuilder? blank;

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(children: quizSpans(context, text, style: style, blank: blank)));
}
