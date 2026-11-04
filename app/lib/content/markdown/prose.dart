// Prose — the lesson Markdown renderer (docs/07 §3, docs/05 §6). Renders the
// block model from grammar.dart; holds no Riverpod state so it can be tested
// in isolation.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../shared/code_block.dart';
import '../../shared/diagram_view.dart';
import '../../shared/lesson_link_chip.dart';
import '../../shared/prose_cards.dart';
import '../../shared/status_dot.dart';
import '../../shared/term_tooltip.dart';
import '../models/models.dart';
import 'blocks.dart';

/// How a section is framed on S3 (docs/01: L1–L3 have 9 sections, L4 11).
enum SectionRole {
  prereqs,
  body,
  tryIt,
  summary;

  static SectionRole of({required int level, required int n}) {
    final l4 = level >= 4;
    if (n == 1) return prereqs;
    if (n == (l4 ? 9 : 7)) return tryIt;
    if (n == (l4 ? 11 : 9)) return summary;
    return body;
  }
}

/// Resolves `[[id]]` targets against the loaded content and progress.
@immutable
class ProseLinks {
  const ProseLinks({
    required this.titleOf,
    required this.isAvailable,
    this.statusOf,
    this.onOpen,
    this.inReview,
    this.onAddReview,
  });

  final String? Function(String id) titleOf;
  final bool Function(String id) isAvailable;
  final LessonStatus Function(String id)? statusOf;
  final ValueChanged<String>? onOpen;

  /// Whether a term (slug) is already an active review item.
  final bool Function(String term)? inReview;

  /// TermTooltip "Thêm vào ôn"; `null` hides the button.
  final Future<void> Function(GlossaryEntry entry)? onAddReview;
}

/// A [TextSpan] for a glossary term (`TermSpan`): dotted underline, tap opens
/// `TermTooltip`.
class TermTextSpan extends TextSpan {
  const TermTextSpan({
    required this.entry,
    super.text,
    super.style,
    super.recognizer,
  });

  final GlossaryEntry entry;
}

class Prose extends StatelessWidget {
  const Prose({
    super.key,
    required this.blocks,
    required this.lang,
    required this.links,
    this.role = SectionRole.body,
    this.lessonId = '',
    this.diagramSvg,
    this.fontSize,
    this.lineHeight,
  });

  final List<ProseBlock> blocks;
  final ContentLang lang;
  final ProseLinks links;
  final SectionRole role;

  /// Owner of `{{diagram}}`.
  final String lessonId;
  final String? diagramSvg;

  /// Reading size (`ReadingPrefs`); defaults to `bodyLarge`.
  final double? fontSize;

  /// Reading line height (`ReadingPrefs`); defaults to `bodyLarge`.
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final body = _ProseBody(prose: this);
    return switch (role) {
      SectionRole.prereqs => PrereqCard(child: body),
      SectionRole.tryIt => TryItPanel(child: body),
      SectionRole.summary => SummaryBox(child: body),
      SectionRole.body => body,
    };
  }
}

class _ProseBody extends StatelessWidget {
  const _ProseBody({required this.prose});

  final Prose prose;

  @override
  Widget build(BuildContext context) => _blocks(context, prose.blocks);

  TextStyle _base(BuildContext context) {
    final s = Theme.of(context).textTheme.bodyLarge!;
    return s.copyWith(fontSize: prose.fontSize, height: prose.lineHeight);
  }

  Widget _blocks(BuildContext context, List<ProseBlock> blocks) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < blocks.length; i++) ...[
        if (i > 0) const SizedBox(height: LtaSpace.s4),
        _block(context, blocks[i]),
      ],
    ],
  );

  Widget _inlines(BuildContext context, List<Inline> inlines, {TextStyle? style}) =>
      _InlineText(
        inlines: inlines,
        style: style ?? _base(context),
        prose: prose,
      );

  Widget _block(BuildContext context, ProseBlock b) {
    final c = Theme.of(context).extension<LtaColors>()!;
    switch (b) {
      case ParagraphBlock(:final inlines):
        return _inlines(context, inlines);
      case CodeBlockData(:final info, :final code):
        return CodeBlock(
          code: code,
          lang: info.lang,
          file: info.file,
          tag: info.tag,
          lineStart: info.lineStart,
          lineEnd: info.lineEnd,
        );
      case OutputBlockData(:final text):
        return OutputBlock(text: text);
      case DiagramBlock():
        return DiagramView(lessonId: prose.lessonId, svg: prose.diagramSvg);
      case ListBlock():
        return _list(context, b);
      case ExpectedBlock(:final label, :final blocks):
        final base = _base(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: base.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: LtaSpace.s1),
            _ItalicScope(child: _blocks(context, blocks)),
          ],
        );
      case DetailsBlock(:final summary, :final blocks):
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: c.line),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: LtaSpace.s3),
            title: Text(summary, style: Theme.of(context).textTheme.labelLarge),
            children: [_blocks(context, blocks)],
          ),
        );
      case TableBlock():
        return _table(context, b);
      case UnsupportedBlock(:final text):
        return Text(text, style: _base(context));
    }
  }

  Widget _list(BuildContext context, ListBlock list) {
    final base = _base(context);
    final children = <Widget>[];
    for (var i = 0; i < list.items.length; i++) {
      final item = list.items[i];
      if (i > 0) children.add(const SizedBox(height: LtaSpace.s3));
      switch (item) {
        case MisconceptionItem(:final belief, :final truth):
          children.add(
            MisconceptionCard(
              belief: _inlines(
                context,
                belief,
                style: base.copyWith(fontWeight: FontWeight.w700),
              ),
              truth: _inlines(context, truth),
            ),
          );
        case LinkItem(:final lessonId, :final relation):
          children.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chip(lessonId),
                if (relation.isNotEmpty) ...[
                  const SizedBox(height: LtaSpace.s1),
                  _inlines(
                    context,
                    relation,
                    style: base.copyWith(
                      color: Theme.of(context).extension<LtaColors>()!.ink2,
                    ),
                  ),
                ],
              ],
            ),
          );
        case PlainItem(:final blocks):
          final marker = list.ordered ? '${list.start + i}.' : '•';
          children.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: LtaSpace.s5,
                  child: Text(marker, style: base),
                ),
                Expanded(child: _blocks(context, blocks)),
              ],
            ),
          );
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _chip(String id) => LessonLinkChip(
    lessonId: id,
    title: prose.links.titleOf(id),
    available: prose.links.isAvailable(id),
    status: prose.links.statusOf?.call(id) ?? LessonStatus.newLesson,
    onTap: prose.links.onOpen == null ? null : () => prose.links.onOpen!(id),
  );

  Widget _table(BuildContext context, TableBlock t) {
    final cols = t.header.length;
    if (cols == 0) {
      debugPrint('prose: table without header');
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    final cellStyle = text.bodyMedium!;
    List<Inline> cell(List<List<Inline>> row, int i) =>
        i < row.length ? row[i] : const [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: text.labelLarge,
        columns: [
          for (final h in t.header)
            DataColumn(
              label: _inlines(
                context,
                h,
                style: cellStyle.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
        rows: [
          for (final r in t.rows)
            DataRow(
              cells: [
                for (var i = 0; i < cols; i++)
                  DataCell(_inlines(context, cell(r, i), style: cellStyle)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Marks a subtree whose inline text renders italic ("Kết quả mong đợi").
class _ItalicScope extends InheritedWidget {
  const _ItalicScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ItalicScope>() != null;

  @override
  bool updateShouldNotify(_ItalicScope oldWidget) => false;
}

/// Inline runs → one `Text.rich`. Owns the term tap recognizers.
class _InlineText extends StatefulWidget {
  const _InlineText({
    required this.inlines,
    required this.style,
    required this.prose,
  });

  final List<Inline> inlines;
  final TextStyle style;
  final Prose prose;

  @override
  State<_InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<_InlineText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _openTerm(GlossaryEntry entry) {
    final links = widget.prose.links;
    showTermTooltip(
      context,
      entry: entry,
      lang: widget.prose.lang,
      learnedInTitle: links.titleOf(entry.introducedIn),
      learnedInAvailable: links.isAvailable(entry.introducedIn),
      onOpenLesson: links.onOpen,
      inReview: links.inReview?.call(entry.term) ?? false,
      onAddReview: links.onAddReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final c = Theme.of(context).extension<LtaColors>()!;
    final code = Theme.of(context).extension<LtaText>()!.code;
    final italicScope = _ItalicScope.of(context);
    final base = widget.style.copyWith(
      fontStyle: italicScope ? FontStyle.italic : null,
    );
    final spans = <InlineSpan>[];
    for (final run in widget.inlines) {
      switch (run) {
        case TextRun(:final text, :final bold, :final italic, :final term):
          var style = TextStyle(
            fontWeight: bold ? FontWeight.w700 : null,
            fontStyle: italic ? FontStyle.italic : null,
          );
          if (term == null) {
            spans.add(TextSpan(text: text, style: style));
          } else {
            style = style.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: c.muted,
            );
            final r = TapGestureRecognizer()..onTap = () => _openTerm(term);
            _recognizers.add(r);
            spans.add(
              TermTextSpan(entry: term, text: text, style: style, recognizer: r),
            );
          }
        case CodeRun(:final text):
          spans.add(
            TextSpan(
              text: text,
              style: code.copyWith(
                fontSize: base.fontSize,
                height: base.height,
                color: c.ink,
                backgroundColor: c.surface2,
                fontStyle: FontStyle.normal,
              ),
            ),
          );
        case LinkRun(:final lessonId):
          final links = widget.prose.links;
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: LessonLinkChip(
                lessonId: lessonId,
                title: links.titleOf(lessonId),
                available: links.isAvailable(lessonId),
                status: links.statusOf?.call(lessonId) ?? LessonStatus.newLesson,
                onTap: links.onOpen == null ? null : () => links.onOpen!(lessonId),
              ),
            ),
          );
        case BreakRun():
          spans.add(const TextSpan(text: '\n'));
      }
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
