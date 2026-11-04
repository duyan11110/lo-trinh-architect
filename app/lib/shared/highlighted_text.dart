// Text with FTS5 highlight markers (search_index.dart) rendered as
// `accentSoft` runs — S9 "đoạn khớp (highlight)".
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../content/search_index.dart';

class HighlightedText extends StatelessWidget {
  const HighlightedText(this.marked, {super.key, this.style, this.maxLines});

  final String marked;
  final TextStyle? style;
  final int? maxLines;

  /// Plain text without markers.
  static String plain(String marked) =>
      marked.replaceAll(searchMarkStart, '').replaceAll(searchMarkEnd, '');

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final base = style ?? DefaultTextStyle.of(context).style;
    final hl = base.copyWith(
      backgroundColor: c.accentSoft,
      color: c.ink,
      fontWeight: FontWeight.w700,
    );
    final spans = <TextSpan>[];
    var rest = marked;
    while (rest.isNotEmpty) {
      final a = rest.indexOf(searchMarkStart);
      if (a < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (a > 0) spans.add(TextSpan(text: rest.substring(0, a)));
      final b = rest.indexOf(searchMarkEnd, a + 1);
      final end = b < 0 ? rest.length : b;
      spans.add(TextSpan(text: rest.substring(a + 1, end), style: hl));
      rest = b < 0 ? '' : rest.substring(b + 1);
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
