/// Markdown parsing helpers shared by L-rules, word counting and term matching.
library markdown_util;

final RegExp fencedCodeBlockRe = RegExp(r'```[^\n]*\n[\s\S]*?\n?```', multiLine: true);
final RegExp inlineCodeRe = RegExp(r'`[^`\n]+`');
final RegExp wikiLinkRe = RegExp(r'\[\[([^\]]+)\]\]');
final RegExp h2LineRe = RegExp(r'^##[ \t].*$', multiLine: true);
final RegExp h2HeadingLineRe = RegExp(r'^##[ \t]+(.*?)\s*$', multiLine: true);

/// A fenced code block found in a lesson body, with its info-string parsed.
class CodeBlock {
  final String lang;
  final Map<String, String> attrs;
  final String content; // raw lines between the fences, no trailing newline
  final int startOffset;
  final int endOffset;
  final String infoLine;

  CodeBlock({
    required this.lang,
    required this.attrs,
    required this.content,
    required this.startOffset,
    required this.endOffset,
    required this.infoLine,
  });

  bool get hasFile => attrs.containsKey('file');
  bool get isOutput => attrs['output'] == 'true';
  String? get file => attrs['file'];
  String? get tag => attrs['tag'];
  String? get linesSpec => attrs['lines'];

  int get lineCount => content.isEmpty ? 0 : content.split('\n').length;
}

/// Parses all fenced code blocks in [body], in document order.
List<CodeBlock> parseCodeBlocks(String body) {
  final blocks = <CodeBlock>[];
  final lines = body.split('\n');
  int i = 0;
  final lineOffsets = <int>[];
  {
    int o = 0;
    for (final l in lines) {
      lineOffsets.add(o);
      o += l.length + 1;
    }
  }
  while (i < lines.length) {
    final line = lines[i];
    final m = RegExp(r'^```(.*)$').firstMatch(line);
    if (m != null) {
      final info = m.group(1) ?? '';
      final startOffset = lineOffsets[i];
      final contentLines = <String>[];
      int j = i + 1;
      while (j < lines.length && lines[j].trim() != '```') {
        contentLines.add(lines[j]);
        j++;
      }
      final endOffset = j < lines.length ? lineOffsets[j] : body.length;
      final tokens = info.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      String lang = '';
      final attrs = <String, String>{};
      if (tokens.isNotEmpty) {
        if (tokens[0].contains('=')) {
          // no lang, starts directly with an attr (shouldn't happen per spec, but be defensive)
        } else {
          lang = tokens[0];
          tokens.removeAt(0);
        }
        for (final t in tokens) {
          final eq = t.indexOf('=');
          if (eq > 0) {
            attrs[t.substring(0, eq)] = t.substring(eq + 1);
          }
        }
      }
      blocks.add(CodeBlock(
        lang: lang,
        attrs: attrs,
        content: contentLines.join('\n'),
        startOffset: startOffset,
        endOffset: endOffset,
        infoLine: info,
      ));
      i = j + 1;
    } else {
      i++;
    }
  }
  return blocks;
}

/// A top-level "## " section of a lesson body.
class Section {
  final int index; // 1-based, in document order
  final String heading; // raw heading text (trimmed)
  final String content; // body markdown between this heading and the next
  final List<CodeBlock> codeBlocks;
  Section(this.index, this.heading, this.content, this.codeBlocks);
}

/// Splits [body] into H2 sections. Anything before the first H2 (e.g. the
/// "Skip this if:" blockquote) is returned separately as [preamble].
class ParsedBody {
  final String preamble;
  final List<Section> sections;
  ParsedBody(this.preamble, this.sections);
}

ParsedBody parseSections(String body) {
  final matches = h2HeadingLineRe.allMatches(body).toList();
  final preamble = matches.isEmpty ? body : body.substring(0, matches.first.start);
  final sections = <Section>[];
  for (int k = 0; k < matches.length; k++) {
    final m = matches[k];
    final heading = m.group(1) ?? '';
    final contentStart = m.end;
    final contentEnd = k + 1 < matches.length ? matches[k + 1].start : body.length;
    final content = body.substring(contentStart, contentEnd);
    sections.add(Section(k + 1, heading.trim(), content, parseCodeBlocks(content)));
  }
  return ParsedBody(preamble, sections);
}

/// A.3 — normalize an H2 title for comparison: trim, collapse whitespace,
/// "..." -> "…", case-insensitive.
String normalizeHeading(String s) {
  var t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  t = t.replaceAll('...', '…');
  return t.toLowerCase();
}

/// A.1 — word count. [bodyNoFrontmatter] must already exclude the frontmatter block.
int countWords(String bodyNoFrontmatter) {
  var s = bodyNoFrontmatter;
  s = s.replaceAll(fencedCodeBlockRe, ' ');
  s = s.replaceAll(h2LineRe, ' ');
  s = s.replaceAllMapped(wikiLinkRe, (m) => ' X ');
  s = s.replaceAllMapped(inlineCodeRe, (m) => ' X ');
  final tokens = s.split(RegExp(r'[\s]+')).where((t) => t.isNotEmpty).toList();
  return tokens.length;
}

/// Strips fenced code blocks, inline code and [[id]] links entirely (for term
/// matching, A.2). Keeps a space in their place so words on either side don't merge.
String stripForTermMatch(String s) {
  var t = s.replaceAll(fencedCodeBlockRe, ' ');
  t = t.replaceAll(inlineCodeRe, ' ');
  t = t.replaceAll(wikiLinkRe, ' ');
  return t;
}

/// Splits text into sentences on '.', '!', '?' followed by whitespace/EOL,
/// ignoring periods inside inline code (already expected to be stripped by caller if needed).
List<String> splitSentences(String text) {
  final t = text.trim();
  if (t.isEmpty) return [];
  final parts = <String>[];
  final re = RegExp(r'[^.!?]*[.!?]+(?=\s|$)|[^.!?]+$');
  for (final m in re.allMatches(t)) {
    final s = m.group(0)?.trim() ?? '';
    if (s.isNotEmpty) parts.add(s);
  }
  return parts;
}

/// Splits a block of prose into paragraphs (blank-line separated), for L18.
List<String> splitParagraphs(String content) {
  return content
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty && !p.startsWith('```'))
      .toList();
}
