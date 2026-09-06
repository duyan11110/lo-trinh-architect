/// A.5 — approximate Mermaid node counting, good enough for the diagram
/// styles this repo actually uses (sequenceDiagram, flowchart, erDiagram,
/// classDiagram) with ≤ 8 nodes.
library mermaid;

String detectDiagramType(String content) {
  final firstLine = content.trim().split('\n').first.trim();
  if (firstLine.startsWith('sequenceDiagram')) return 'sequenceDiagram';
  if (firstLine.startsWith('flowchart') || firstLine.startsWith('graph')) return 'flowchart';
  if (firstLine.startsWith('erDiagram')) return 'erDiagram';
  if (firstLine.startsWith('classDiagram')) return 'classDiagram';
  return 'unknown';
}

int countNodes(String content) {
  final type = detectDiagramType(content);
  switch (type) {
    case 'sequenceDiagram':
      return _countSequenceParticipants(content);
    case 'flowchart':
      return _countFlowchartNodes(content);
    case 'erDiagram':
      return _countErEntities(content);
    case 'classDiagram':
      return _countClasses(content);
    default:
      return 0;
  }
}

int _countSequenceParticipants(String content) {
  final ids = <String>{};
  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('%%')) continue;
    if (line.startsWith('sequenceDiagram')) continue;
    final decl = RegExp(r'^participant\s+(\S+)').firstMatch(line);
    if (decl != null) {
      ids.add(decl.group(1)!);
      continue;
    }
    final arrow = RegExp(r'^([A-Za-z0-9_]+)\s*(-{1,2}>{1,2}|--x|-\)|\.{2}>)\s*([A-Za-z0-9_]+)').firstMatch(line);
    if (arrow != null) {
      ids.add(arrow.group(1)!);
      ids.add(arrow.group(3)!);
    }
  }
  return ids.length;
}

final RegExp _arrowRe = RegExp(r'-\.->|-->|---|===|==>|-\.-|--');

int _countFlowchartNodes(String content) {
  final ids = <String>{};
  final lines = content.split('\n');
  for (final rawLine in lines) {
    var line = rawLine.trim();
    if (line.isEmpty || line.startsWith('%%')) continue;
    if (RegExp(r'^(flowchart|graph)\s').hasMatch(line)) continue;
    if (RegExp(r'^(classDef|style|click|linkStyle|subgraph|end)\b').hasMatch(line)) continue;
    // Strip an edge label |...|
    line = line.replaceAll(RegExp(r'\|[^|]*\|'), ' ');
    final parts = line.split(_arrowRe);
    for (final part in parts) {
      final m = RegExp(r'^\s*([A-Za-z0-9_]+)').firstMatch(part);
      if (m != null) ids.add(m.group(1)!);
    }
  }
  return ids.length;
}

int _countErEntities(String content) {
  final ids = <String>{};
  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('erDiagram') || line.startsWith('%%')) continue;
    final rel = RegExp(r'^([A-Za-z0-9_]+)\s+[|o}{.\-]+--[|o}{.\-]+\s+([A-Za-z0-9_]+)\s*:').firstMatch(line);
    if (rel != null) {
      ids.add(rel.group(1)!);
      ids.add(rel.group(2)!);
    }
  }
  return ids.length;
}

int _countClasses(String content) {
  final ids = <String>{};
  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('classDiagram') || line.startsWith('%%')) continue;
    final decl = RegExp(r'^class\s+([A-Za-z0-9_]+)').firstMatch(line);
    if (decl != null) {
      ids.add(decl.group(1)!);
      continue;
    }
    final rel = RegExp(r'^([A-Za-z0-9_]+)\s*(?:"[^"]*")?\s*(?:<\|--|--\*|--o|-->|--\||\.\.>|\.\.\|>)\s*(?:"[^"]*")?\s*([A-Za-z0-9_]+)').firstMatch(line);
    if (rel != null) {
      ids.add(rel.group(1)!);
      ids.add(rel.group(2)!);
    }
  }
  return ids.length;
}
