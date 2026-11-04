// Render model produced by `grammar.dart` from the Markdown AST and consumed
// by `prose.dart`. Pure data — no Flutter widgets here.
import 'package:flutter/foundation.dart';

import '../models/models.dart';

// ---------------------------------------------------------------- inlines

/// Flattened inline run. Nesting (bold inside italic…) is folded into flags.
@immutable
sealed class Inline {
  const Inline();
}

@immutable
class TextRun extends Inline {
  const TextRun(this.text, {this.bold = false, this.italic = false, this.term});

  final String text;
  final bool bold;
  final bool italic;

  /// Glossary entry when this run is a term (`TermSpan`).
  final GlossaryEntry? term;

  TextRun copyWith({String? text, GlossaryEntry? term}) => TextRun(
    text ?? this.text,
    bold: bold,
    italic: italic,
    term: term ?? this.term,
  );
}

/// Inline code: never term-matched.
@immutable
class CodeRun extends Inline {
  const CodeRun(this.text);
  final String text;
}

/// `[[lesson.id]]` → `LessonLinkChip`.
@immutable
class LinkRun extends Inline {
  const LinkRun(this.lessonId);
  final String lessonId;
}

/// Hard line break inside a paragraph.
@immutable
class BreakRun extends Inline {
  const BreakRun();
}

// ---------------------------------------------------------------- blocks

@immutable
sealed class ProseBlock {
  const ProseBlock();
}

@immutable
class ParagraphBlock extends ProseBlock {
  const ParagraphBlock(this.inlines);
  final List<Inline> inlines;
}

/// Parsed fence info string (docs/07 §3): `LANG file=PATH tag=TAG
/// [lines=a-b]` or `text output=true`.
@immutable
class FenceInfo {
  const FenceInfo({
    required this.lang,
    this.file,
    this.tag,
    this.lineStart,
    this.lineEnd,
    this.output = false,
  });

  final String? lang;
  final String? file;
  final String? tag;
  final int? lineStart;
  final int? lineEnd;
  final bool output;

  /// `file` and `tag` both present, in the fixed order.
  bool get isSourceRef => file != null && tag != null;
}

/// Source fence (`LANG file=… tag=…`) → `CodeBlock`. When [info] is not a valid source
/// reference the block is still shown as mono text without header chips.
@immutable
class CodeBlockData extends ProseBlock {
  const CodeBlockData(this.info, this.code);
  final FenceInfo info;
  final String code;
}

/// ` ```text output=true` → `OutputBlock`.
@immutable
class OutputBlockData extends ProseBlock {
  const OutputBlockData(this.text);
  final String text;
}

/// A line that is exactly `{{diagram}}` → `DiagramView`.
@immutable
class DiagramBlock extends ProseBlock {
  const DiagramBlock();
}

@immutable
class ListBlock extends ProseBlock {
  const ListBlock({required this.ordered, required this.start, required this.items});
  final bool ordered;
  final int start;
  final List<ListItem> items;
}

@immutable
sealed class ListItem {
  const ListItem();
}

@immutable
class PlainItem extends ListItem {
  const PlainItem(this.blocks);
  final List<ProseBlock> blocks;
}

/// `- **"…"** → …` → `MisconceptionCard`.
@immutable
class MisconceptionItem extends ListItem {
  const MisconceptionItem(this.belief, this.truth);
  final List<Inline> belief;
  final List<Inline> truth;
}

/// `- [[id]] — …` → `LessonLinkChip` + relation text.
@immutable
class LinkItem extends ListItem {
  const LinkItem(this.lessonId, this.relation);
  final String lessonId;
  final List<Inline> relation;
}

/// `Expected result:` / `Kết quả mong đợi:` through the end of the section
/// (except a `<details>` hint) → `TryItPanel.expected`.
@immutable
class ExpectedBlock extends ProseBlock {
  const ExpectedBlock(this.label, this.blocks);

  /// The label as written in the lesson, without the colon — it follows the
  /// content language, not the UI locale.
  final String label;
  final List<ProseBlock> blocks;
}

/// `<details><summary>…</summary>…</details>` → `ExpansionTile`.
@immutable
class DetailsBlock extends ProseBlock {
  const DetailsBlock(this.summary, this.blocks);
  final String summary;
  final List<ProseBlock> blocks;
}

/// GFM table → `DataTable` in a horizontal scroll view.
@immutable
class TableBlock extends ProseBlock {
  const TableBlock(this.header, this.rows);
  final List<List<Inline>> header;
  final List<List<List<Inline>>> rows;
}

/// Anything outside docs/07 §3: shown as plain text (and `debugPrint`ed by
/// the parser), never a crash.
@immutable
class UnsupportedBlock extends ProseBlock {
  const UnsupportedBlock(this.text);
  final String text;
}
