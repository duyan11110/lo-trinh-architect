/// Minimal, correctness-first YAML emitter used by merge-outline.
///
/// This does not attempt to preserve comments or the exact flow/block style of
/// a hand-edited file (Dart has no round-trip-preserving YAML editor on
/// pub.dev); it always produces valid YAML that this repo's own loader
/// (package:yaml) reads back byte-for-value identically to the input map.
library yaml_writer;

const List<String> _reservedWords = [
  'true', 'false', 'yes', 'no', 'on', 'off', 'null', '~',
  'True', 'False', 'Yes', 'No', 'On', 'Off', 'Null',
  'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', 'NULL',
];

bool _isSimpleScalar(String s) {
  if (s.isEmpty) return false;
  if (_reservedWords.contains(s)) return false;
  if (num.tryParse(s) != null) return false;
  return RegExp(r'^[A-Za-z][A-Za-z0-9_\-./]*$').hasMatch(s);
}

String _quoteString(String s) {
  final buf = StringBuffer('"');
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    switch (ch) {
      case '\\':
        buf.write(r'\\');
        break;
      case '"':
        buf.write(r'\"');
        break;
      case '\n':
        buf.write(r'\n');
        break;
      case '\t':
        buf.write(r'\t');
        break;
      default:
        buf.write(ch);
    }
  }
  buf.write('"');
  return buf.toString();
}

String scalarToYaml(dynamic v) {
  if (v == null) return 'null';
  if (v is bool) return v.toString();
  if (v is num) return v.toString();
  final s = v.toString();
  return _isSimpleScalar(s) ? s : _quoteString(s);
}

bool _isFlowSafeList(List v) {
  if (v.isEmpty) return true;
  return v.every((e) => e is String || e is num || e is bool) &&
      v.fold<int>(0, (a, e) => a + e.toString().length) < 90;
}

String _indent(int n) => '  ' * n;

/// Serializes [value] (Map/List/scalars, as produced by yamlToPlain) as a
/// YAML document body (no leading `---`).
String toYaml(dynamic value) {
  final buf = StringBuffer();
  _writeNode(buf, value, 0, topLevel: true);
  return buf.toString();
}

void _writeNode(StringBuffer buf, dynamic value, int indent, {bool topLevel = false}) {
  if (value is Map) {
    if (value.isEmpty) {
      buf.writeln('{}');
      return;
    }
    var first = true;
    for (final entry in value.entries) {
      if (!first || !topLevel) buf.write(_indent(indent));
      first = false;
      final key = scalarToYaml(entry.key.toString());
      final v = entry.value;
      if (v is Map && v.isNotEmpty) {
        buf.writeln('$key:');
        _writeNode(buf, v, indent + 1);
      } else if (v is List && v.isNotEmpty && !_isFlowSafeList(v)) {
        buf.writeln('$key:');
        _writeListBlock(buf, v, indent);
      } else if (v is List) {
        buf.writeln('$key: ${_flowList(v)}');
      } else if (v is Map) {
        buf.writeln('$key: {}');
      } else {
        buf.writeln('$key: ${scalarToYaml(v)}');
      }
    }
  } else if (value is List) {
    if (value.isEmpty) {
      buf.writeln('[]');
      return;
    }
    _writeListBlock(buf, value, indent - 1);
  } else {
    buf.writeln(scalarToYaml(value));
  }
}

void _writeListBlock(StringBuffer buf, List value, int indent) {
  for (final item in value) {
    buf.write(_indent(indent));
    buf.write('- ');
    if (item is Map && item.isNotEmpty) {
      var first = true;
      for (final entry in item.entries) {
        if (!first) buf.write(_indent(indent + 1));
        first = false;
        final key = scalarToYaml(entry.key.toString());
        final v = entry.value;
        if (v is Map && v.isNotEmpty) {
          buf.writeln('$key:');
          _writeNode(buf, v, indent + 2);
        } else if (v is List && v.isNotEmpty && !_isFlowSafeList(v)) {
          buf.writeln('$key:');
          _writeListBlock(buf, v, indent + 1);
        } else if (v is List) {
          buf.writeln('$key: ${_flowList(v)}');
        } else {
          buf.writeln('$key: ${scalarToYaml(v)}');
        }
      }
    } else if (item is List) {
      buf.writeln();
      _writeListBlock(buf, item, indent + 1);
    } else {
      buf.writeln(scalarToYaml(item));
    }
  }
}

String _flowList(List v) {
  if (v.isEmpty) return '[]';
  return '[${v.map((e) => scalarToYaml(e)).join(', ')}]';
}
