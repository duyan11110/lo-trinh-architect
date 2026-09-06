/// L01–L18 — lesson frontmatter and body rules.
library rules_lesson;

import 'code_source.dart';
import 'content_tree.dart';
import 'errors.dart';
import 'headings.dart';
import 'markdown_util.dart';
import 'mermaid.dart' as mermaid;
import 'glossary.dart';
import 'schema_validator.dart';

final RegExp _urlRe = RegExp(r'(https?://|www\.)\S+', caseSensitive: false);
final List<String> _forbiddenPhrases = [
  'latest version',
  'recently',
  'nowadays',
  "in today's",
  'in conclusion',
];

Section? sectionAt(List<Section> sections, int idx) {
  for (final s in sections) {
    if (s.index == idx) return s;
  }
  return null;
}

class LessonValidationInput {
  final String id; // reporting key: frontmatter id, or file path if unknown
  final Map<String, dynamic> frontmatter;
  final String body; // body only, no frontmatter
  final ContentTree? tree; // null => skip tree cross-checks (--file mode)
  final CodeSource? codeSource;
  final bool noRepo;
  LessonValidationInput({
    required this.id,
    required this.frontmatter,
    required this.body,
    this.tree,
    this.codeSource,
    this.noRepo = false,
  });
}

void validateLesson(LessonValidationInput input, SchemaValidator sv, IssueCollector out) {
  final fm = input.frontmatter;
  final id = (fm['id'] as String?) ?? input.id;
  final lang = fm['lang'] as String? ?? 'en';
  final level = (fm['level'] as int?) ?? 1;
  final stage = (fm['stage'] as int?) ?? 0;
  final mainPath = fm['main_path'] as bool? ?? true;

  final schemaErrs = sv.validate('lesson-frontmatter.schema.json', fm);
  for (final e in schemaErrs) {
    out.error(id, 'L01', 'frontmatter không qua schema: $e');
  }

  final lesson = input.tree?.lesson(id);
  if (lesson != null) {
    _compareFrontmatterToTrack(id, fm, lesson, lang, out);
  }

  final parsed = parseSections(input.body);
  _checkL02Headings(id, parsed, lang, level, stage, out);
  _checkL03SkipBlockquote(id, parsed, lang, mainPath, out);
  _checkL04BeforeYouStart(id, parsed, lang, fm, level, out);
  _checkL05Situation(id, parsed, level, out);
  _checkL06CoreConcepts(id, parsed, level, fm, lang, input.tree, out);
  _checkL07HowItWorks(id, parsed, level, out);
  _checkL08Code(id, parsed, level, fm, lesson, input, out);
  _checkL09Misconceptions(id, parsed, level, out);
  _checkL10TryIt(id, parsed, lang, level, out);
  _checkL11Connections(id, parsed, level, lesson, input.tree, out);
  _checkL12Summary(id, parsed, level, out);
  _checkL13TotalWords(id, input.body, level, out);
  _checkL14Urls(id, input.body, out);
  _checkL1516TermsAndBold(id, input.body, parsed, level, lang, fm, input.tree, out);
  _checkL17Forbidden(id, input.body, out);
  _checkL18Paragraphs(id, parsed, out);
}

bool _sameSet(List<String> a, List<String> b) {
  final sa = a.toSet();
  final sb = b.toSet();
  return sa.length == sb.length && sa.containsAll(sb);
}

void _compareFrontmatterToTrack(
    String id, Map<String, dynamic> fm, LessonEntry lesson, String lang, IssueCollector out) {
  final titleMap = lesson.title;
  if (titleMap != null) {
    final expectedTitle = titleMap[lang];
    if (expectedTitle != null && fm['title'] != expectedTitle) {
      out.error(id, 'L01', 'title lệch với track.yaml (${lang}: "$expectedTitle")');
    }
  }
  final fmSkills = ((fm['skills'] as List?) ?? []).map((e) => e.toString()).toList();
  if (!_sameSet(fmSkills, lesson.skills)) {
    out.error(id, 'L01', 'skills lệch với track.yaml');
  }
  final fmPrereqs = ((fm['prereqs'] as List?) ?? []).map((e) => e.toString()).toList();
  if (!_sameSet(fmPrereqs, lesson.prereqs)) {
    out.error(id, 'L01', 'prereqs lệch với track.yaml');
  }
  final fmVocab = ((fm['vocab'] as List?) ?? []).map((e) => e.toString()).toList();
  if (!_sameSet(fmVocab, lesson.vocab)) {
    out.error(id, 'L01', 'vocab lệch với track.yaml');
  }
  if (fm['example_tag'] != lesson.exampleTag) {
    out.error(id, 'L01', 'example_tag lệch với track.yaml');
  }
  if (fm['main_path'] != lesson.mainPath) {
    out.error(id, 'L01', 'main_path lệch với track.yaml');
  }
  if (fm['duration_min'] != lesson.durationMin) {
    out.error(id, 'L01', 'duration_min lệch với track.yaml');
  }
}

void _checkL02Headings(
    String id, ParsedBody parsed, String lang, int level, int stage, IssueCollector out) {
  final expected = expectedHeadings(lang, level, stage);
  final actual = parsed.sections.map((s) => s.heading).toList();
  bool ok = actual.length == expected.length;
  if (ok) {
    for (int i = 0; i < expected.length; i++) {
      if (!headingsMatch(actual[i], expected[i])) {
        ok = false;
        break;
      }
    }
  }
  if (!ok) {
    out.error(id, 'L02',
        'mục H2 sai/thiếu/thừa/sai thứ tự. Mong đợi: ${expected.join(" | ")}. Thực tế: ${actual.join(" | ")}');
  }
}

void _checkL03SkipBlockquote(String id, ParsedBody parsed, String lang, bool mainPath, IssueCollector out) {
  final marker = lang == 'vi' ? 'Bỏ qua được nếu' : 'Skip this if';
  final hasBlockquote = RegExp('^>\\s*.*${RegExp.escape(marker)}', multiLine: true).hasMatch(parsed.preamble);
  if (!mainPath && !hasBlockquote) {
    out.error(id, 'L03', 'bài main_path:false thiếu blockquote "$marker" trước mục 1');
  }
  if (mainPath && hasBlockquote) {
    out.error(id, 'L03', 'bài main_path:true không được có blockquote "$marker"');
  }
}

final RegExp _bulletLineRe = RegExp(r'^\s*-\s+(.*)$', multiLine: true);

List<String> _bullets(String content) =>
    _bulletLineRe.allMatches(content).map((m) => m.group(1)!.trim()).toList();

void _checkL04BeforeYouStart(
    String id, ParsedBody parsed, String lang, Map<String, dynamic> fm, int level, IssueCollector out) {
  final section = sectionAt(parsed.sections, beforeYouStartSectionIndex(level));
  if (section == null) return;
  final bullets = _bullets(section.content);
  final prereqs = ((fm['prereqs'] as List?) ?? []).map((e) => e.toString()).toList();
  if (prereqs.isEmpty) {
    final expected = lang == 'vi'
        ? 'Không cần gì trước — bắt đầu từ đây.'
        : 'No prerequisites — start here.';
    if (bullets.length != 1) {
      out.error(id, 'L04', 'mục 1: bài không có prereq phải có đúng 1 bullet');
    } else {
      final b = bullets.first;
      final withoutLink = b.replaceAll(wikiLinkRe, '').trim();
      if (wikiLinkRe.hasMatch(b) || withoutLink != expected) {
        out.error(id, 'L04', 'mục 1: bullet duy nhất phải đúng "$expected", không link');
      }
    }
    return;
  }
  if (bullets.length != prereqs.length) {
    out.error(id, 'L04', 'mục 1: số bullet (${bullets.length}) khác số prereqs (${prereqs.length})');
  }
  final linkedIds = <String>{};
  for (final b in bullets) {
    final matches = wikiLinkRe.allMatches(b).toList();
    if (matches.length != 1) {
      out.error(id, 'L04', 'mục 1: mỗi bullet phải chứa đúng một [[id]] — "$b"');
      continue;
    }
    linkedIds.add(matches.first.group(1)!);
  }
  if (linkedIds.length != prereqs.toSet().length || !linkedIds.containsAll(prereqs)) {
    out.error(id, 'L04', 'mục 1: tập id trong bullet phải bằng đúng tập prereqs');
  }
}

void _checkL05Situation(String id, ParsedBody parsed, int level, IssueCollector out) {
  final section = sectionAt(parsed.sections, situationSectionIndex(level));
  if (section == null) return;
  final wc = countWords(section.content);
  if (wc < 60 || wc > 120) {
    out.error(id, 'L05', 'mục 2: $wc từ, phải trong khoảng 60–120');
  }
  final sentences = splitSentences(section.content);
  if (sentences.isEmpty || !sentences.last.trim().endsWith('?')) {
    out.error(id, 'L05', 'mục 2: câu cuối phải kết thúc bằng dấu hỏi');
  }
}

final RegExp _boldRe = RegExp(r'\*\*([^*]+)\*\*');

String _termDisplay(String slug, ContentTree? tree, String lang) {
  final g = tree?.glossaryTerm(slug);
  if (g != null) {
    final d = lang == 'vi' ? g.vi : g.en;
    if (d.isNotEmpty) return d;
  }
  return slug.replaceAll('-', ' ');
}

void _checkL06CoreConcepts(String id, ParsedBody parsed, int level, Map<String, dynamic> fm, String lang,
    ContentTree? tree, IssueCollector out) {
  final section = sectionAt(parsed.sections, coreConceptsSectionIndex(level));
  if (section == null) return;
  final bullets = _bullets(section.content);
  if (bullets.length < 3 || bullets.length > 6) {
    out.error(id, 'L06', 'mục 3: ${bullets.length} bullet, phải 3–6');
  }
  final vocab = ((fm['vocab'] as List?) ?? []).map((e) => e.toString()).toList();
  final boldedInSection = _boldRe.allMatches(section.content).map((m) => m.group(1)!.trim()).toList();
  for (final term in vocab) {
    final display = _termDisplay(term, tree, lang);
    final count = boldedInSection.where((b) => b.toLowerCase() == display.toLowerCase()).length;
    if (count != 1) {
      out.error(id, 'L06', 'mục 3: term vocab "$term" ($display) phải in đậm đúng một lần (thấy $count lần)');
    }
  }
}

void _checkL07HowItWorks(String id, ParsedBody parsed, int level, IssueCollector out) {
  final section = sectionAt(parsed.sections, howItWorksSectionIndex(level));
  if (section == null) return;
  final mermaidBlocks = section.codeBlocks.where((b) => b.lang == 'mermaid').toList();
  if (mermaidBlocks.length != 1) {
    out.error(id, 'L07', 'mục 4: phải có đúng 1 khối mermaid (thấy ${mermaidBlocks.length})');
  } else {
    final nodeCount = mermaid.countNodes(mermaidBlocks.first.content);
    if (nodeCount > 8) {
      out.error(id, 'L07', 'mục 4: mermaid có $nodeCount node, vượt quá 8');
    }
  }
  final prose = section.content.replaceAll(fencedCodeBlockRe, ' ');
  final wc = countWords(prose);
  if (wc < 150 || wc > 300) {
    out.error(id, 'L07', 'mục 4: văn xuôi $wc từ, phải trong khoảng 150–300');
  }
}

String _stripExtension(String path) {
  final idx = path.lastIndexOf('.');
  final slashIdx = path.lastIndexOf('/');
  if (idx <= slashIdx) return path;
  return path.substring(0, idx);
}

void _checkL08Code(String id, ParsedBody parsed, int level, Map<String, dynamic> fm, LessonEntry? lesson,
    LessonValidationInput input, IssueCollector out) {
  final section = sectionAt(parsed.sections, inSystemSectionIndex(level));
  if (section == null) return;
  final blocks = section.codeBlocks;
  final fileBlocks = blocks.where((b) => b.hasFile).toList();
  if (fileBlocks.length > 2) {
    out.error(id, 'L08', 'mục 5: có ${fileBlocks.length} code block có file=, tối đa 2');
  }
  final exampleTag = fm['example_tag'] as String?;
  for (final b in fileBlocks) {
    if (b.lineCount > 25) {
      out.error(id, 'L08', 'mục 5: block "${b.file}" có ${b.lineCount} dòng, tối đa 25');
    }
    if (exampleTag != null && b.tag != exampleTag) {
      out.error(id, 'L08', 'mục 5: tag="${b.tag}" khác example_tag="$exampleTag"');
    }
    if (lesson != null && !lesson.exampleFiles.contains(b.file)) {
      out.error(id, 'L08', 'mục 5: file="${b.file}" không có trong example_files của bài');
    }
    _checkCodeContentMatch(id, b, input, out);
  }
  for (int i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    if (b.lang == 'text' && !b.hasFile && !b.isOutput) {
      out.error(id, 'L08', 'mục 5: block text không có cả file= lẫn output=true');
      continue;
    }
    if (b.isOutput) {
      final prev = i > 0 ? blocks[i - 1] : null;
      if (prev == null || !prev.hasFile) {
        out.error(id, 'L08b', 'mục 5: block output=true phải đứng ngay sau một block có file= trỏ tới script');
        continue;
      }
      _checkOutputMatch(id, b, prev, exampleTag, input, out);
    }
  }
}

void _checkCodeContentMatch(String id, CodeBlock b, LessonValidationInput input, IssueCollector out) {
  if (input.noRepo) return;
  final source = input.codeSource;
  if (source == null || b.file == null || b.tag == null) return;
  final tagOk = source.tagExists(b.tag!);
  final content = source.readFile(b.tag!, b.file!);
  if (content == null) {
    if (!tagOk || source.isRepoDirMode) {
      out.warn(id, 'S07', 'không kiểm được code "${b.file}": tag "${b.tag}" chưa tồn tại (hoặc chưa có trong --repo-dir)');
    } else {
      out.error(id, 'S07', 'file "${b.file}" không tồn tại ở tag "${b.tag}" trong repo ví dụ');
    }
    return;
  }
  final err = matchCodeBlock(blockContent: b.content, fileContent: content, linesSpec: b.linesSpec);
  if (err != null) {
    out.error(id, 'L08', 'mục 5: block "${b.file}" $err');
  }
}

void _checkOutputMatch(String id, CodeBlock outBlock, CodeBlock scriptBlock, String? exampleTag,
    LessonValidationInput input, IssueCollector out) {
  if (input.noRepo) return;
  final source = input.codeSource;
  if (source == null || scriptBlock.file == null) return;
  final tag = scriptBlock.tag ?? exampleTag;
  if (tag == null) return;
  final withoutExt = _stripExtension(scriptBlock.file!);
  final outputPath = 'outputs/$tag/$withoutExt.txt';
  final tagOk = source.tagExists(tag);
  final content = source.readFile(tag, outputPath);
  if (content == null) {
    if (!tagOk || source.isRepoDirMode) {
      out.warn(id, 'S07', 'không kiểm được output: tag "$tag" chưa tồn tại (hoặc chưa có trong --repo-dir)');
    } else {
      out.warn(id, 'L08b', 'không tìm thấy file output "$outputPath" trong repo ví dụ');
    }
    return;
  }
  if (!matchOutputBlock(blockContent: outBlock.content, fileContent: content)) {
    out.error(id, 'L08b', 'mục 5: block output không khớp "$outputPath"');
  }
}

final RegExp _misconceptionBulletRe = RegExp(r'^\*\*"[^"]*"\*\*\s*→\s*.+');
final RegExp _misconceptionQuoteRe = RegExp(r'\*\*"([^"]*)"\*\*');

/// The quoted "belief" half of every bullet in the lesson's mục 6/8
/// (misconceptions) section — used by both L09 and quiz rule Q06.
List<String> extractMisconceptionBeliefs(String body, int level) {
  final parsed = parseSections(body);
  final section = sectionAt(parsed.sections, misconceptionsSectionIndex(level));
  if (section == null) return [];
  return _misconceptionQuoteRe.allMatches(section.content).map((m) => m.group(1)!).toList();
}

void _checkL09Misconceptions(String id, ParsedBody parsed, int level, IssueCollector out) {
  final idx = misconceptionsSectionIndex(level);
  final section = sectionAt(parsed.sections, idx);
  if (section == null) return;
  final bullets = _bullets(section.content);
  if (bullets.length < 2) {
    out.error(id, 'L09', 'mục ngộ nhận: cần ≥ 2 bullet, thấy ${bullets.length}');
  }
  for (final b in bullets) {
    if (!_misconceptionBulletRe.hasMatch(b)) {
      out.error(id, 'L09', 'mục ngộ nhận: bullet phải bắt đầu **"…"** rồi → — sai: "$b"');
    }
  }
}

void _checkL10TryIt(String id, ParsedBody parsed, String lang, int level, IssueCollector out) {
  final section = sectionAt(parsed.sections, tryItSectionIndex(level));
  if (section == null) return;
  final marker = lang == 'vi' ? 'Kết quả mong đợi:' : 'Expected result:';
  if (!RegExp('^\\s*${RegExp.escape(marker)}', multiLine: true).hasMatch(section.content)) {
    out.error(id, 'L10', 'mục Thử ngay: thiếu dòng bắt đầu "$marker"');
  }
}

void _checkL11Connections(
    String id, ParsedBody parsed, int level, LessonEntry? lesson, ContentTree? tree, IssueCollector out) {
  final section = sectionAt(parsed.sections, connectionsSectionIndex(level));
  if (section == null) return;
  final ids = wikiLinkRe.allMatches(section.content).map((m) => m.group(1)!).toList();
  if (ids.length < 2) {
    out.error(id, 'L11', 'mục Liên hệ: cần ≥ 2 [[id]], thấy ${ids.length}');
  }
  if (tree == null) return;
  final existing = ids.where((i) => tree.lesson(i) != null).toList();
  if (existing.isEmpty) {
    out.error(id, 'L11', 'mục Liên hệ: cần ≥ 1 link tới bài đã tồn tại');
  }
  if (lesson != null) {
    for (final relId in lesson.related) {
      if (ids.contains(relId)) continue;
      if (tree.lesson(relId) != null) {
        out.error(id, 'L11', 'mục Liên hệ: thiếu link tới related "$relId" (đã tồn tại)');
      } else {
        out.warn(id, 'L11', 'mục Liên hệ: related "$relId" chưa outline (chip "sắp có")');
      }
    }
  }
  for (final linkedId in ids) {
    if (tree.lesson(linkedId) == null) {
      out.warn(id, 'L11', 'mục Liên hệ: [[$linkedId]] chưa tồn tại (chip "sắp có")');
    }
  }
}

void _checkL12Summary(String id, ParsedBody parsed, int level, IssueCollector out) {
  final section = sectionAt(parsed.sections, summarySectionIndex(level));
  if (section == null) return;
  final lines = section.content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  if (lines.length != 5) {
    out.error(id, 'L12', 'mục Tóm tắt: phải đúng 5 dòng, thấy ${lines.length}');
    return;
  }
  for (int i = 0; i < 5; i++) {
    final expectedPrefix = '${i + 1}.';
    if (!lines[i].startsWith(expectedPrefix)) {
      out.error(id, 'L12', 'mục Tóm tắt: dòng ${i + 1} phải đánh số "$expectedPrefix"');
      continue;
    }
    final text = lines[i].substring(expectedPrefix.length).trim();
    final wc = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).length;
    if (wc > 25) {
      out.error(id, 'L12', 'mục Tóm tắt: dòng ${i + 1} có $wc từ, tối đa 25');
    }
  }
}

void _checkL13TotalWords(String id, String body, int level, IssueCollector out) {
  final wc = countWords(body);
  final maxAllowed = level == 4 ? 2000 : 1600;
  if (wc < 900 || wc > maxAllowed) {
    out.error(id, 'L13', 'tổng $wc từ, phải trong khoảng 900–$maxAllowed');
  }
}

void _checkL14Urls(String id, String body, IssueCollector out) {
  final withoutCode = body.replaceAll(fencedCodeBlockRe, ' ').replaceAll(inlineCodeRe, ' ');
  if (_urlRe.hasMatch(withoutCode)) {
    out.error(id, 'L14', 'thân bài chứa URL');
  }
}

void _checkL1516TermsAndBold(String id, String body, ParsedBody parsed, int level, String lang,
    Map<String, dynamic> fm, ContentTree? tree, IssueCollector out) {
  final vocab = ((fm['vocab'] as List?) ?? []).map((e) => e.toString()).toList();
  final vocabDisplay = vocab.map((t) => _termDisplay(t, tree, lang).toLowerCase()).toSet();

  final miscSection = sectionAt(parsed.sections, misconceptionsSectionIndex(level));
  final miscContent = miscSection?.content ?? '';
  final bodyNoCode = body.replaceAll(fencedCodeBlockRe, ' ');
  for (final m in _boldRe.allMatches(bodyNoCode)) {
    final text = m.group(1)!.trim();
    if (vocabDisplay.contains(text.toLowerCase())) continue;
    if (text.startsWith('"') && text.endsWith('"') && miscContent.contains(m.group(0)!)) {
      continue;
    }
    out.warn(id, 'L16', 'in đậm "$text" không phải term vocab và không phải câu ngộ nhận trích dẫn');
  }

  if (tree == null) return;
  final lessonId = fm['id'] as String?;
  final lesson = lessonId != null ? tree.lesson(lessonId) : null;
  if (lesson == null) return;
  final knownVocabTerms = <String>{};
  for (final l in tree.lessonsInGlobalOrder) {
    if (l.globalOrder >= 0 && lesson.globalOrder >= 0 && l.globalOrder < lesson.globalOrder) {
      knownVocabTerms.addAll(l.vocab);
    }
  }
  final allowed = <String>{...knownVocabTerms, ...vocab};
  final matches = findTermOccurrences(bodyNoCode, tree.glossary);
  final reportedTerms = <String>{};
  for (final m in matches) {
    if (allowed.contains(m.term)) continue;
    if (reportedTerms.contains(m.term)) continue;
    reportedTerms.add(m.term);
    out.warn(id, 'L15', 'dùng thuật ngữ "${m.term}" ngoài known_vocab ∪ vocab');
  }
}

void _checkL17Forbidden(String id, String body, IssueCollector out) {
  final withoutCode = body.replaceAll(fencedCodeBlockRe, ' ').replaceAll(inlineCodeRe, ' ');
  final lower = withoutCode.toLowerCase();
  for (final phrase in _forbiddenPhrases) {
    if (lower.contains(phrase)) {
      out.error(id, 'L17', 'chuỗi cấm: "$phrase"');
    }
  }
  if (withoutCode.contains('!')) {
    out.error(id, 'L17', 'dấu "!" ngoài code');
  }
  for (final sentence in splitSentences(withoutCode)) {
    final sLower = sentence.toLowerCase();
    if (sLower.contains('best practice') && !sLower.contains('when') && !sLower.contains('if')) {
      out.error(id, 'L17', 'chuỗi cấm: "best practice" thiếu điều kiện "when"/"if" trong câu: "$sentence"');
    }
  }
}

void _checkL18Paragraphs(String id, ParsedBody parsed, IssueCollector out) {
  for (final section in parsed.sections) {
    final content = section.content.replaceAll(fencedCodeBlockRe, ' ');
    for (final para in splitParagraphs(content)) {
      if (para.startsWith('-') || RegExp(r'^\d+\.').hasMatch(para) || para.startsWith('>')) continue;
      final sentences = splitSentences(para);
      if (sentences.length > 6) {
        out.error(id, 'L18', 'mục ${section.index}: đoạn văn có ${sentences.length} câu, tối đa 6');
      }
    }
  }
}
