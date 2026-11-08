// Extended Markdown grammar — docs/07 §3 (the build ↔ renderer contract).
//
// `markdown` (GFM extension set) produces the AST; every extension is
// recognised on the AST / inline level, never by regex on rendered output.
// Anything outside §3 becomes plain text plus a `debugPrint`, never a throw.
import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart' as md;

import '../glossary_matcher.dart';
import 'blocks.dart';

/// Inline `[[lesson.id]]` (docs/07 §3).
class LessonLinkSyntax extends md.InlineSyntax {
  LessonLinkSyntax() : super(r'\[\[([a-z0-9.-]+)\]\]', startCharacter: 0x5B);

  static const tag = 'lesson-link';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty(tag)..attributes['id'] = match[1]!);
    return true;
  }
}

/// Parses a fence info string. [info] is everything after the backticks.
/// Order of keys is fixed (`file`, `tag`, `lines`), separated by one space,
/// unquoted. Returns a [FenceInfo] whose [FenceInfo.isSourceRef] is false when
/// the keys are missing or malformed.
FenceInfo parseFenceInfo(String info) {
  final trimmed = info.trim();
  if (trimmed.isEmpty) return const FenceInfo(lang: null);
  final parts = trimmed.split(' ');
  final lang = parts.first;
  final rest = parts.sublist(1);

  if (rest.length == 1 && rest.first == 'output=true') {
    if (lang == 'text') return const FenceInfo(lang: 'text', output: true);
    debugPrint('prose: output=true on non-text fence "$trimmed"');
    return FenceInfo(lang: lang);
  }

  String? valueOf(int i, String key) {
    if (i >= rest.length) return null;
    final p = rest[i];
    final prefix = '$key=';
    if (!p.startsWith(prefix) || p.length == prefix.length) return null;
    return p.substring(prefix.length);
  }

  final file = valueOf(0, 'file');
  final tag = valueOf(1, 'tag');
  final lines = valueOf(2, 'lines');
  int? a;
  int? b;
  var ok = file != null && tag != null && rest.length <= 3;
  if (ok && rest.length == 3) {
    final m = RegExp(r'^(\d+)-(\d+)$').firstMatch(lines ?? '');
    if (m == null) {
      ok = false;
    } else {
      a = int.parse(m[1]!);
      b = int.parse(m[2]!);
    }
  }
  if (!ok) {
    if (rest.isNotEmpty || lang != 'mermaid') {
      debugPrint('prose: fence info outside grammar "$trimmed"');
    }
    return FenceInfo(lang: lang);
  }
  return FenceInfo(lang: lang, file: file, tag: tag, lineStart: a, lineEnd: b);
}

/// Markdown section → [ProseBlock]s, with glossary terms resolved for one
/// language.
class ProseParser {
  ProseParser({required this.matcher});

  final GlossaryMatcher matcher;

  static const diagramToken = '{{diagram}}';
  static const expectedPrefixes = ['Expected result:', 'Kết quả mong đợi:'];
  static const _misconceptionArrow = ' → ';
  static const _relationDash = '—';

  static const _blockTags = {
    'p', 'ul', 'ol', 'pre', 'table', 'blockquote', 'hr', //
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  };

  List<ProseBlock> parse(String markdown) {
    final nodes = _document().parse(markdown.replaceAll('\r\n', '\n'));
    return _groupExpected(_blocks(nodes));
  }

  md.Document _document() => md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    inlineSyntaxes: [LessonLinkSyntax()],
    encodeHtml: false,
  );

  // ------------------------------------------------------------- blocks

  List<ProseBlock> _blocks(List<md.Node> nodes) {
    final out = <ProseBlock>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is md.Text && _isDetailsOpen(node.text)) {
        i = _details(nodes, i, out);
        continue;
      }
      out.addAll(_block(node));
    }
    return out;
  }

  static bool _isDetailsOpen(String raw) =>
      raw.trimLeft().toLowerCase().startsWith('<details');

  static final _summaryRe = RegExp(
    r'<summary>(.*?)</summary>',
    dotAll: true,
    caseSensitive: false,
  );
  static final _detailsOpenRe = RegExp(r'<details[^>]*>', caseSensitive: false);
  static final _detailsCloseRe = RegExp(r'</details>', caseSensitive: false);

  /// Consumes a `<details>` block starting at [start]; returns the index of
  /// the last consumed node. Inner content is parsed again as Markdown.
  int _details(List<md.Node> nodes, int start, List<ProseBlock> out) {
    var raw = (nodes[start] as md.Text).text;
    raw = raw.replaceFirst(_detailsOpenRe, '');
    final sm = _summaryRe.firstMatch(raw);
    final summary = sm == null ? '' : sm[1]!.trim();
    if (sm != null) raw = raw.substring(sm.end);

    final inner = <ProseBlock>[];
    var trailing = '';
    var end = start;
    final close = _detailsCloseRe.firstMatch(raw);
    if (close != null) {
      inner.addAll(parse(raw.substring(0, close.start)));
      trailing = raw.substring(close.end);
    } else {
      if (raw.trim().isNotEmpty) inner.addAll(parse(raw));
      var closed = false;
      for (var j = start + 1; j < nodes.length; j++) {
        end = j;
        final n = nodes[j];
        if (n is md.Text) {
          final c = _detailsCloseRe.firstMatch(n.text);
          if (c != null) {
            final before = n.text.substring(0, c.start);
            if (before.trim().isNotEmpty) inner.addAll(parse(before));
            trailing = n.text.substring(c.end);
            closed = true;
            break;
          }
        }
        inner.addAll(_blocks([n]));
      }
      if (!closed) debugPrint('prose: <details> without </details>');
    }
    if (sm == null) debugPrint('prose: <details> without <summary>');
    out.add(DetailsBlock(summary, inner));
    if (trailing.trim().isNotEmpty) out.addAll(parse(trailing));
    return end;
  }

  List<ProseBlock> _block(md.Node node) {
    if (node is md.Text) {
      final t = node.text.trim();
      if (t.isEmpty) return const [];
      debugPrint('prose: unsupported HTML block "${_clip(t)}"');
      return [UnsupportedBlock(t)];
    }
    if (node is! md.Element) return const [];
    switch (node.tag) {
      case 'p':
        final inlines = _inlines(node.children ?? const []);
        if (node.textContent.trim() == diagramToken) {
          return const [DiagramBlock()];
        }
        return [ParagraphBlock(inlines)];
      case 'pre':
        return [_pre(node)];
      case 'ul':
      case 'ol':
        return [_list(node)];
      case 'table':
        return [_table(node)];
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        debugPrint('prose: heading ${node.tag} inside a section');
        return [ParagraphBlock(_inlines(node.children ?? const []))];
      case 'blockquote':
        debugPrint('prose: blockquote inside a section');
        return _blocks(node.children ?? const []);
      case 'hr':
        debugPrint('prose: thematic break inside a section');
        return const [];
      default:
        debugPrint('prose: unsupported block <${node.tag}>');
        final t = node.textContent.trim();
        return t.isEmpty ? const [] : [UnsupportedBlock(t)];
    }
  }

  ProseBlock _pre(md.Element pre) {
    final code = (pre.children?.isNotEmpty ?? false) ? pre.children!.first : null;
    var text = code?.textContent ?? pre.textContent;
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    String? lang;
    if (code is md.Element) {
      final cls = code.attributes['class'];
      if (cls != null && cls.startsWith('language-')) {
        lang = cls.substring('language-'.length);
      }
    }
    final meta = pre.attributes['data-metadata'];
    final info = parseFenceInfo([?lang, ?meta].join(' '));
    if (info.output) return OutputBlockData(text);
    if (info.lang == 'mermaid') {
      debugPrint('prose: mermaid fence reached the app (build should replace)');
    }
    return CodeBlockData(info, text);
  }

  ListBlock _list(md.Element list) {
    final ordered = list.tag == 'ol';
    final start = int.tryParse(list.attributes['start'] ?? '') ?? 1;
    final items = <ListItem>[];
    for (final li in list.children ?? const <md.Node>[]) {
      if (li is! md.Element || li.tag != 'li') continue;
      items.add(_item(li));
    }
    return ListBlock(ordered: ordered, start: start, items: items);
  }

  ListItem _item(md.Element li) {
    final children = li.children ?? const <md.Node>[];
    final isBlocky = children.any(
      (c) => c is md.Element && _blockTags.contains(c.tag),
    );
    final blocks = isBlocky
        ? _blocks(children)
        : <ProseBlock>[ParagraphBlock(_inlines(children))];

    if (blocks.length == 1 && blocks.first is ParagraphBlock) {
      final inlines = (blocks.first as ParagraphBlock).inlines;
      return _linkItem(inlines) ?? _misconception(inlines) ?? PlainItem(blocks);
    }
    return PlainItem(blocks);
  }

  /// `[[id]] — relation`.
  LinkItem? _linkItem(List<Inline> inlines) {
    if (inlines.length < 2) return null;
    final first = inlines.first;
    final second = inlines[1];
    if (first is! LinkRun || second is! TextRun) return null;
    final t = second.text.trimLeft();
    if (!t.startsWith(_relationDash)) return null;
    final head = t.substring(_relationDash.length).trimLeft();
    final relation = <Inline>[
      if (head.isNotEmpty) second.copyWith(text: head),
      ...inlines.skip(2),
    ];
    return LinkItem(first.lessonId, relation);
  }

  /// `**"belief"** → truth`, split at the first ` → `.
  MisconceptionItem? _misconception(List<Inline> inlines) {
    final first = inlines.firstOrNull;
    if (first is! TextRun || !first.bold) return null;
    final lead = first.text.trimLeft();
    if (!(lead.startsWith('"') || lead.startsWith('“'))) return null;
    for (var i = 0; i < inlines.length; i++) {
      final r = inlines[i];
      if (r is! TextRun) continue;
      final at = r.text.indexOf(_misconceptionArrow);
      if (at < 0) continue;
      final before = r.text.substring(0, at);
      final after = r.text.substring(at + _misconceptionArrow.length);
      final belief = <Inline>[
        ...inlines.take(i),
        if (before.trim().isNotEmpty) r.copyWith(text: before),
      ];
      final truth = <Inline>[
        if (after.trim().isNotEmpty) r.copyWith(text: after.trimLeft()),
        ...inlines.skip(i + 1),
      ];
      return MisconceptionItem(belief, truth);
    }
    return null;
  }

  TableBlock _table(md.Element table) {
    final header = <List<Inline>>[];
    final rows = <List<List<Inline>>>[];
    for (final section in table.children ?? const <md.Node>[]) {
      if (section is! md.Element) continue;
      for (final tr in section.children ?? const <md.Node>[]) {
        if (tr is! md.Element || tr.tag != 'tr') continue;
        final cells = [
          for (final cell in tr.children ?? const <md.Node>[])
            if (cell is md.Element) _inlines(cell.children ?? const []),
        ];
        if (section.tag == 'thead') {
          header.addAll(cells);
        } else {
          rows.add(cells);
        }
      }
    }
    return TableBlock(header, rows);
  }

  /// Post-pass: `Expected result:` paragraph plus what follows it to the end
  /// of the section, stopping at a `<details>` hint.
  List<ProseBlock> _groupExpected(List<ProseBlock> blocks) {
    final out = <ProseBlock>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final hit = b is ParagraphBlock ? _stripExpected(b.inlines) : null;
      if (hit == null) {
        out.add(b);
        continue;
      }
      final (label, stripped) = hit;
      final group = <ProseBlock>[
        if (stripped.isNotEmpty) ParagraphBlock(stripped),
      ];
      var j = i + 1;
      while (j < blocks.length && blocks[j] is! DetailsBlock) {
        group.add(blocks[j]);
        j++;
      }
      out.add(ExpectedBlock(label, group));
      i = j - 1;
    }
    return out;
  }

  static (String, List<Inline>)? _stripExpected(List<Inline> inlines) {
    final first = inlines.firstOrNull;
    if (first is! TextRun) return null;
    for (final p in expectedPrefixes) {
      if (first.text.startsWith(p)) {
        final rest = first.text.substring(p.length).trimLeft();
        return (
          p.substring(0, p.length - 1),
          [if (rest.isNotEmpty) first.copyWith(text: rest), ...inlines.skip(1)],
        );
      }
    }
    return null;
  }

  // ------------------------------------------------------------- inlines

  List<Inline> _inlines(List<md.Node> nodes) =>
      _applyGlossary(_merge(_collect(nodes, bold: false, italic: false)));

  List<Inline> _collect(
    List<md.Node> nodes, {
    required bool bold,
    required bool italic,
  }) {
    final out = <Inline>[];
    for (final n in nodes) {
      if (n is md.Text) {
        final t = n.text.replaceAll('\n', ' ');
        if (t.isNotEmpty) out.add(TextRun(t, bold: bold, italic: italic));
        continue;
      }
      if (n is! md.Element) continue;
      final kids = n.children ?? const <md.Node>[];
      switch (n.tag) {
        case 'strong':
          final runs = _merge(_collect(kids, bold: true, italic: italic));
          final entry = runs.every((r) => r is TextRun)
              ? matcher.exact(runs.map((r) => (r as TextRun).text).join())
              : null;
          out.addAll(
            entry == null
                ? runs
                : runs.map((r) => (r as TextRun).copyWith(term: entry)),
          );
        case 'em':
          out.addAll(_collect(kids, bold: bold, italic: true));
        case 'code':
          out.add(CodeRun(n.textContent));
        case LessonLinkSyntax.tag:
          out.add(LinkRun(n.attributes['id']!));
        case 'br':
          out.add(const BreakRun());
        default:
          // Links, images, strikethrough, inline HTML: text only.
          debugPrint('prose: unsupported inline <${n.tag}>');
          final text = n.tag == 'img'
              ? (n.attributes['alt'] ?? '')
              : n.textContent;
          if (text.isNotEmpty) {
            out.add(TextRun(text, bold: bold, italic: italic));
          }
      }
    }
    return out;
  }

  /// Joins adjacent text runs with identical style so glossary matching sees
  /// whole phrases (the parser splits text at special characters).
  static List<Inline> _merge(List<Inline> runs) {
    final out = <Inline>[];
    for (final r in runs) {
      final last = out.lastOrNull;
      if (r is TextRun &&
          last is TextRun &&
          last.bold == r.bold &&
          last.italic == r.italic &&
          identical(last.term, r.term)) {
        out[out.length - 1] = last.copyWith(text: last.text + r.text);
      } else {
        out.add(r);
      }
    }
    return out;
  }

  List<Inline> _applyGlossary(List<Inline> runs) {
    final out = <Inline>[];
    for (final r in runs) {
      if (r is! TextRun || r.term != null) {
        out.add(r);
        continue;
      }
      final matches = matcher.match(r.text);
      var pos = 0;
      for (final m in matches) {
        if (m.start > pos) out.add(r.copyWith(text: r.text.substring(pos, m.start)));
        out.add(r.copyWith(text: r.text.substring(m.start, m.end), term: m.entry));
        pos = m.end;
      }
      if (pos < r.text.length) out.add(r.copyWith(text: r.text.substring(pos)));
    }
    return out;
  }

  static String _clip(String s) => s.length <= 40 ? s : '${s.substring(0, 40)}…';
}
