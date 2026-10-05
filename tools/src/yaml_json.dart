/// Helpers to load YAML/JSON files into plain Dart Map/List structures
/// (String keys, no YamlMap/YamlList/YamlScalar wrappers) so the rest of the
/// codebase can treat YAML- and JSON-sourced data uniformly.
library yaml_json;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

dynamic yamlToPlain(dynamic node) {
  if (node is YamlMap) {
    final map = <String, dynamic>{};
    for (final entry in node.entries) {
      map[entry.key.toString()] = yamlToPlain(entry.value);
    }
    return map;
  } else if (node is YamlList) {
    return node.map(yamlToPlain).toList();
  } else {
    return node;
  }
}

dynamic loadYamlFile(String path) {
  final text = File(path).readAsStringSync();
  final doc = loadYaml(text);
  return yamlToPlain(doc);
}

dynamic loadJsonFile(String path) {
  final text = File(path).readAsStringSync();
  return jsonDecode(text);
}

/// Splits a Markdown lesson file into (frontmatter map, body string).
/// Frontmatter is the YAML block delimited by `---` lines at the top of the file.
class FrontmatterDoc {
  final Map<String, dynamic> frontmatter;
  final String body;
  final String raw;
  FrontmatterDoc(this.frontmatter, this.body, this.raw);
}

FrontmatterDoc parseFrontmatter(String path) {
  final raw = File(path).readAsStringSync();
  return parseFrontmatterFromString(raw);
}

FrontmatterDoc parseFrontmatterFromString(String raw) {
  final normalized = raw.replaceAll('\r\n', '\n');
  if (!normalized.startsWith('---\n') && normalized.trim() != '---') {
    return FrontmatterDoc(<String, dynamic>{}, normalized, raw);
  }
  final lines = normalized.split('\n');
  if (lines.isEmpty || lines[0] != '---') {
    return FrontmatterDoc(<String, dynamic>{}, normalized, raw);
  }
  int endIdx = -1;
  for (int i = 1; i < lines.length; i++) {
    if (lines[i] == '---') {
      endIdx = i;
      break;
    }
  }
  if (endIdx == -1) {
    return FrontmatterDoc(<String, dynamic>{}, normalized, raw);
  }
  final fmText = lines.sublist(1, endIdx).join('\n');
  final body = lines.sublist(endIdx + 1).join('\n');
  dynamic fm;
  try {
    fm = yamlToPlain(loadYaml(fmText));
  } catch (_) {
    fm = <String, dynamic>{};
  }
  return FrontmatterDoc(
    (fm is Map<String, dynamic>) ? fm : <String, dynamic>{},
    body,
    raw,
  );
}
