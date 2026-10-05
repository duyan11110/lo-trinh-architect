/// P01–P04 — VI/EN parity rules (only run with `validate --parity <id>`).
library rules_parity;

import 'content_tree.dart';
import 'errors.dart';
import 'markdown_util.dart';

final RegExp _bulletLineRe = RegExp(r'^\s*-\s+(.*)$', multiLine: true);
List<String> _bullets(String content) => _bulletLineRe.allMatches(content).map((m) => m.group(1)!).toList();

bool _deepEquals(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_deepEquals(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

void validateParity(
  String id,
  Map<String, dynamic> fmEn,
  String bodyEn,
  Map<String, dynamic> fmVi,
  String bodyVi,
  LessonEntry? lesson,
  ContentTree? tree,
  IssueCollector out,
) {
  final fmEnCopy = Map<String, dynamic>.from(fmEn)
    ..remove('lang')
    ..remove('title');
  final fmViCopy = Map<String, dynamic>.from(fmVi)
    ..remove('lang')
    ..remove('title');
  if (!_deepEquals(fmEnCopy, fmViCopy)) {
    out.error(id, 'P01', 'frontmatter VI/EN khác nhau ngoài lang/title');
  }
  if (lesson?.title != null) {
    final expectedViTitle = lesson!.title!['vi'];
    if (expectedViTitle != null && fmVi['title'] != expectedViTitle) {
      out.error(id, 'P01', 'title VI phải bằng title.vi trong track.yaml');
    }
  }

  final parsedEn = parseSections(bodyEn);
  final parsedVi = parseSections(bodyVi);
  if (parsedEn.sections.length != parsedVi.sections.length) {
    out.error(id, 'P02', 'số mục H2 khác nhau (EN ${parsedEn.sections.length} vs VI ${parsedVi.sections.length})');
  }
  final codeEn = parseCodeBlocks(bodyEn);
  final codeVi = parseCodeBlocks(bodyVi);
  if (codeEn.length != codeVi.length) {
    out.error(id, 'P02', 'số code block khác nhau (EN ${codeEn.length} vs VI ${codeVi.length})');
  } else {
    for (int i = 0; i < codeEn.length; i++) {
      if (codeEn[i].content != codeVi[i].content) {
        out.error(id, 'P02', 'nội dung code block #${i + 1} khác nhau giữa EN/VI');
      }
    }
  }
  final linksEn = wikiLinkRe.allMatches(bodyEn).length;
  final linksVi = wikiLinkRe.allMatches(bodyVi).length;
  if (linksEn != linksVi) {
    out.error(id, 'P02', 'số [[id]] khác nhau (EN $linksEn vs VI $linksVi)');
  }

  for (final idx in [1, 3, 6, 8]) {
    Section? findSection(ParsedBody p, int i) {
      for (final s in p.sections) {
        if (s.index == i) return s;
      }
      return null;
    }

    final sEn = findSection(parsedEn, idx);
    final sVi = findSection(parsedVi, idx);
    if (sEn == null || sVi == null) continue;
    final bEn = _bullets(sEn.content).length;
    final bVi = _bullets(sVi.content).length;
    if (bEn != bVi) {
      out.error(id, 'P02', 'mục $idx: số bullet khác nhau (EN $bEn vs VI $bVi)');
    }
  }
  Section? section9(ParsedBody p) {
    for (final s in p.sections) {
      if (s.index == 9) return s;
    }
    return null;
  }

  final sEn9 = section9(parsedEn);
  final sVi9 = section9(parsedVi);
  if (sEn9 != null && sVi9 != null) {
    final lEn = sEn9.content.split('\n').where((l) => l.trim().isNotEmpty).length;
    final lVi = sVi9.content.split('\n').where((l) => l.trim().isNotEmpty).length;
    if (lEn != lVi) {
      out.error(id, 'P02', 'mục 9: số dòng khác nhau (EN $lEn vs VI $lVi)');
    }
  }

  // P03 — vi_keep terms
  if (tree != null) {
    final vocab = ((fmEn['vocab'] as List?) ?? []).map((e) => e.toString()).toList();
    for (final term in vocab) {
      final g = tree.glossaryTerm(term);
      if (g == null) continue;
      if (g.viKeep) {
        if (g.en.isNotEmpty && !bodyVi.toLowerCase().contains(g.en.toLowerCase())) {
          out.error(id, 'P03', 'term "$term" có vi_keep=true nhưng không thấy "${g.en}" trong bản VI (có thể đã bị dịch)');
        }
      } else {
        if (g.vi.isNotEmpty && !bodyVi.contains(g.vi)) {
          out.error(id, 'P03', 'term "$term" có vi_keep=false nhưng không thấy đúng từ "${g.vi}" trong bản VI');
        }
      }
    }
  }

  // P04
  for (final phrase in ['được thực hiện bởi', 'một cách']) {
    if (bodyVi.contains(phrase)) {
      out.warn(id, 'P04', 'bản VI chứa cụm "$phrase"');
    }
  }
}
