/// Mermaid SVG post-processing for `tools/build` (docs/07 §6, tools/SPEC.md
/// "build" step 2). The app substitutes 3 sentinel colors for theme tokens at
/// load time, so the SVG tools/build emits must:
///  - contain no `<style>` or `<foreignObject>` element (inline every rule as
///    plain presentation attributes instead);
///  - drop any white background fill mermaid draws behind the diagram;
///  - force the app's font family on the root so text renders correctly
///    even before the app applies its own theme.
library svg_theming;

const String sentinelText = '#010101'; // text/stroke
const String sentinelNodeFill = '#020202'; // node background
const String sentinelBorder = '#030303'; // node border
const String kFontFamily = 'Be Vietnam Pro, sans-serif';

final RegExp _foreignObjectRe =
    RegExp(r'<foreignObject\b[^>]*>[\s\S]*?</foreignObject>', caseSensitive: false);
final RegExp _styleBlockRe = RegExp(r'<style\b[^>]*>([\s\S]*?)</style>', caseSensitive: false);
final RegExp _cssRuleRe = RegExp(r'([^{}]+)\{([^{}]*)\}');
final RegExp _tagRe = RegExp(r'<([a-zA-Z][\w:-]*)([^>]*?)(/?)>');
final RegExp _attrRe = RegExp(r'([a-zA-Z_:][-\w:.]*)\s*=\s*"([^"]*)"');
final RegExp _whiteFillRe =
    RegExp(r'(fill\s*[:=]\s*"?)(#fff(?:fff)?|white)("?)', caseSensitive: false);

Map<String, Map<String, String>> _parseCss(String css) {
  final rules = <String, Map<String, String>>{};
  for (final m in _cssRuleRe.allMatches(css)) {
    final selectorGroup = m.group(1)!.trim();
    final body = m.group(2)!;
    final props = <String, String>{};
    for (final decl in body.split(';')) {
      final idx = decl.indexOf(':');
      if (idx <= 0) continue;
      final prop = decl.substring(0, idx).trim();
      final value = decl.substring(idx + 1).trim();
      if (prop.isNotEmpty && value.isNotEmpty) props[prop] = value;
    }
    if (props.isEmpty) continue;
    for (final selector in selectorGroup.split(',')) {
      rules[selector.trim()] = {...(rules[selector.trim()] ?? {}), ...props};
    }
  }
  return rules;
}

List<String> _classesOf(String tagAttrs) {
  final m = RegExp(r'class\s*=\s*"([^"]*)"').firstMatch(tagAttrs);
  if (m == null) return [];
  return m.group(1)!.split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toList();
}

Map<String, String> _inlineStyleOf(String tagAttrs) {
  final m = RegExp(r'style\s*=\s*"([^"]*)"').firstMatch(tagAttrs);
  if (m == null) return {};
  final props = <String, String>{};
  for (final decl in m.group(1)!.split(';')) {
    final idx = decl.indexOf(':');
    if (idx <= 0) continue;
    props[decl.substring(0, idx).trim()] = decl.substring(idx + 1).trim();
  }
  return props;
}

/// A conservative allow-list of CSS properties that are also valid SVG
/// presentation attributes, so "inline CSS to attributes" is a direct rename.
const Set<String> _presentationProps = {
  'fill',
  'stroke',
  'stroke-width',
  'font-family',
  'font-size',
  'font-weight',
  'opacity',
  'stroke-dasharray',
  'text-anchor',
};

String _rewriteTagAttributes(String tagName, String attrs, Map<String, Map<String, String>> rules) {
  final classes = _classesOf(attrs);
  final merged = <String, String>{};
  // tag-only rules, then class rules (in encounter order), then inline style — later wins.
  if (rules.containsKey(tagName)) merged.addAll(rules[tagName]!);
  for (final c in classes) {
    if (rules.containsKey('.$c')) merged.addAll(rules['.$c']!);
    if (rules.containsKey('$tagName.$c')) merged.addAll(rules['$tagName.$c']!);
  }
  merged.addAll(_inlineStyleOf(attrs));
  if (merged.isEmpty) return attrs;

  final existingAttrNames = _attrRe.allMatches(attrs).map((m) => m.group(1)!).toSet();
  final additions = StringBuffer();
  merged.forEach((prop, value) {
    if (!_presentationProps.contains(prop)) return;
    if (existingAttrNames.contains(prop)) return;
    additions.write(' $prop="$value"');
  });
  var result = attrs.replaceAll(RegExp(r'\s*style\s*=\s*"[^"]*"'), '');
  result = '$result${additions.toString()}';
  return result;
}

/// Runs the full docs/07 §6 post-processing pipeline on mmdc's raw SVG output.
String postprocessMermaidSvg(String rawSvg) {
  var svg = rawSvg.replaceAll(_foreignObjectRe, '');

  final rules = <String, Map<String, String>>{};
  for (final m in _styleBlockRe.allMatches(svg)) {
    rules.addAll(_parseCss(m.group(1)!));
  }
  svg = svg.replaceAll(_styleBlockRe, '');

  svg = svg.replaceAllMapped(_tagRe, (m) {
    final tagName = m.group(1)!;
    final attrs = m.group(2)!;
    final selfClose = m.group(3)!;
    if (tagName.toLowerCase() == 'style') return '';
    final newAttrs = _rewriteTagAttributes(tagName, attrs, rules);
    return '<$tagName$newAttrs$selfClose>';
  });

  // Drop the white background mermaid draws behind the whole diagram.
  svg = svg.replaceAllMapped(_whiteFillRe, (m) => '${m.group(1)}none${m.group(3)}');

  // Force the app's font family on the root <svg> element.
  svg = svg.replaceFirstMapped(RegExp(r'<svg([^>]*)>'), (m) {
    var attrs = m.group(1)!;
    attrs = attrs.replaceAll(RegExp(r'\s*font-family\s*=\s*"[^"]*"'), '');
    return '<svg$attrs font-family="$kFontFamily">';
  });

  return svg;
}

/// Builds a mermaid-cli themeVariables config that renders text/strokes,
/// node fill and node border as the 3 sentinel colors, with a transparent
/// background (belt-and-braces alongside [postprocessMermaidSvg]'s white-fill
/// removal).
String mermaidConfigJson() => '''
{
  "theme": "base",
  "themeVariables": {
    "primaryColor": "$sentinelNodeFill",
    "primaryTextColor": "$sentinelText",
    "primaryBorderColor": "$sentinelBorder",
    "lineColor": "$sentinelText",
    "textColor": "$sentinelText",
    "background": "transparent",
    "mainBkg": "$sentinelNodeFill",
    "nodeBorder": "$sentinelBorder",
    "actorBkg": "$sentinelNodeFill",
    "actorBorder": "$sentinelBorder",
    "actorTextColor": "$sentinelText",
    "signalColor": "$sentinelText",
    "signalTextColor": "$sentinelText"
  }
}
''';
