// CodeBlock / OutputBlock — docs/05 §6, docs/07 §3. Mono, horizontal scroll,
// no wrap, no line numbers; dark `codeBg` in both themes.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

import '../app/theme/text.dart';
import '../app/theme/tokens.dart';
import '../l10n/app_localizations.dart';

class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.lang,
    this.file,
    this.tag,
    this.lineStart,
    this.lineEnd,
  });

  final String code;
  final String? lang;
  final String? file;
  final String? tag;
  final int? lineStart;
  final int? lineEnd;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = Theme.of(context).extension<LtaColors>()!;
    final codeStyle = Theme.of(context).extension<LtaText>()!.code;
    const d = LtaColors.dark;
    final chipStyle = codeStyle.copyWith(color: d.ink2);

    Widget chip(String text) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LtaSpace.s2,
        vertical: LtaSpace.s1 / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LtaRadius.chip),
        border: Border.all(color: d.line, width: LtaSize.border),
      ),
      child: Text(text, style: chipStyle, overflow: TextOverflow.ellipsis),
    );

    final hasHeader = file != null || tag != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.codeBg,
        borderRadius: BorderRadius.circular(LtaRadius.code),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: LtaSpace.s3,
              top: LtaSpace.s1,
            ),
            child: Row(
              children: [
                if (hasHeader)
                  Expanded(
                    child: GestureDetector(
                      onTap: file == null || tag == null
                          ? null
                          : () => _toast(context, l.codeSource(file!, tag!)),
                      child: Wrap(
                        spacing: LtaSpace.s2,
                        runSpacing: LtaSpace.s1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (file != null) chip(file!),
                          if (tag != null) chip(tag!),
                          if (lineStart != null && lineEnd != null)
                            Text(l.codeLines(lineStart!, lineEnd!), style: chipStyle),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                IconButton(
                  tooltip: l.codeCopy,
                  color: d.ink2,
                  icon: const Icon(Icons.content_copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) _toast(context, l.codeCopied);
                  },
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              LtaSpace.s3,
              0,
              LtaSpace.s3,
              LtaSpace.s3,
            ),
            child: SelectableText.rich(
              TextSpan(style: codeStyle, children: _highlight(code, lang)),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Syntax colouring via `highlight`; unknown language → plain (docs/07 §2).
  static List<TextSpan> _highlight(String code, String? lang) {
    if (lang == null || lang == 'text') return [TextSpan(text: code)];
    try {
      final nodes = highlight.parse(code, language: lang).nodes;
      if (nodes == null) return [TextSpan(text: code)];
      final colors = LtaCodeSyntax.colors;
      TextSpan convert(Node n) {
        final color = colors[n.className];
        final style = color == null ? null : TextStyle(color: color);
        if (n.value != null) return TextSpan(text: n.value, style: style);
        return TextSpan(
          style: style,
          children: [for (final k in n.children ?? const <Node>[]) convert(k)],
        );
      }

      return [for (final n in nodes) convert(n)];
    } catch (_) {
      return [TextSpan(text: code)];
    }
  }
}

/// ` ```text output=true` — `surface2` background, "output" label, mono.
class OutputBlock extends StatelessWidget {
  const OutputBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final t = Theme.of(context).extension<LtaText>()!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(LtaRadius.code),
        border: Border.all(color: c.line, width: LtaSize.border),
      ),
      padding: const EdgeInsets.all(LtaSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.of(context).outputLabel.toUpperCase(), style: t.eyebrow),
          const SizedBox(height: LtaSpace.s2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(text, style: t.code.copyWith(color: c.ink)),
          ),
        ],
      ),
    );
  }
}
