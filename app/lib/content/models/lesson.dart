// `lessons[id]` of content.json (docs/04 §1, schemas/content.schema.json).
import 'package:flutter/foundation.dart';

import 'i18n.dart';

@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.track,
    required this.level,
    required this.stage,
    required this.module,
    required this.mainPath,
    required this.durationMin,
    required this.title,
    required this.skills,
    required this.prereqs,
    required this.related,
    required this.vocab,
    required this.exampleTag,
    required this.sectionsVi,
    required this.sectionsEn,
    required this.diagramSvg,
    required this.skipNote,
    required this.contentVersion,
  });

  factory Lesson.fromJson(Object? json) {
    final m = asMap(json, 'lessons{}');
    final sections = asMap(m['sections'], 'sections');
    List<LessonSection> secs(String lang) => List.unmodifiable(
      asList(sections[lang], 'sections.$lang').map(LessonSection.fromJson),
    );
    final skip = m['skip_note'];
    return Lesson(
      id: m.str('id'),
      track: m.str('track'),
      level: m.integer('level'),
      stage: m.integer('stage'),
      module: m.str('module'),
      mainPath: m.boolean('main_path'),
      durationMin: m.integer('duration_min'),
      title: m.i18n('title'),
      skills: m.strings('skills'),
      prereqs: m.strings('prereqs'),
      related: m.strings('related'),
      vocab: m.strings('vocab'),
      exampleTag: m.str('example_tag'),
      sectionsVi: secs('vi'),
      sectionsEn: secs('en'),
      diagramSvg: m.strOrNull('diagram_svg'),
      skipNote: skip == null ? null : _skipNote(asMap(skip, 'skip_note')),
      contentVersion: m.integer('content_version'),
    );
  }

  /// Schema allows `vi`/`en` to be individually absent; fall back to the
  /// other language rather than dropping the banner.
  static I18n _skipNote(JsonMap m) {
    final vi = m.strOrNull('vi');
    final en = m.strOrNull('en');
    return I18n(vi: vi ?? en ?? '', en: en ?? vi ?? '');
  }

  final String id;
  final String track;
  final int level;
  final int stage;

  /// Module id inside [track] (not `track/module`).
  final String module;
  final bool mainPath;
  final int durationMin;
  final I18n title;
  final List<String> skills;
  final List<String> prereqs;
  final List<String> related;
  final List<String> vocab;
  final String exampleTag;
  final List<LessonSection> sectionsVi;
  final List<LessonSection> sectionsEn;

  /// Mermaid already rendered by `tools/build`, with sentinel colours
  /// (docs/07 §6). `null` when the build could not render it.
  final String? diagramSvg;
  final I18n? skipNote;
  final int contentVersion;

  String get moduleKey => '$track/$module';

  List<LessonSection> sections(ContentLang lang) =>
      lang == ContentLang.vi ? sectionsVi : sectionsEn;
}

@immutable
class LessonSection {
  const LessonSection({required this.n, required this.heading, required this.md});

  factory LessonSection.fromJson(Object? json) {
    final m = asMap(json, 'section');
    return LessonSection(
      n: m.integer('n'),
      heading: m.str('heading'),
      md: m.str('md'),
    );
  }

  /// 1-based section number (L1–L3: 1–9, L4: 1–11; docs/01).
  final int n;
  final String heading;
  final String md;
}
