// `lessons[id]` of content.json (docs/04 §1, schemas/content.schema.json).
import 'package:flutter/foundation.dart';

import 'i18n.dart';
import 'json_slice.dart';

@immutable
class Lesson {
  Lesson({
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
    required List<LessonSection> sectionsVi,
    required List<LessonSection> sectionsEn,
    required String? diagramSvg,
    required this.skipNote,
    required this.contentVersion,
  }) : sectionsData = LessonSections(vi: sectionsVi, en: sectionsEn),
       _svg = diagramSvg;

  Lesson._({
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
    required this.sectionsData,
    required this._svg,
    required this.skipNote,
    required this.contentVersion,
  });

  factory Lesson.fromJson(Object? json) {
    final m = asMap(json, 'lessons{}');
    final sections = m['sections'];
    final svg = m['diagram_svg'];
    final skip = m['skip_note'];
    return Lesson._(
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
      sectionsData: sections is JsonSlice
          ? LessonSections.lazy(id: m.str('id'), slice: sections)
          : LessonSections.fromJson(sections),
      svg: svg is JsonSlice || svg is String ? svg : null,
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

  /// Both languages' sections; decoded on each read when loaded lazily
  /// (the parsed blocks are cached by `ProseCache`).
  final LessonSections sectionsData;

  /// `String`, a not yet decoded [JsonSlice], or `null`.
  final Object? _svg;

  List<LessonSection> get sectionsVi => sectionsData.of(ContentLang.vi);
  List<LessonSection> get sectionsEn => sectionsData.of(ContentLang.en);

  /// Mermaid already rendered by `tools/build`, with sentinel colours
  /// (docs/07 §6). `null` when the build could not render it. Decoded on
  /// first use and kept (only lessons actually opened pay for it).
  late final String? diagramSvg = switch (_svg) {
    final String svg => svg,
    final JsonSlice slice => _decodeSvg(slice),
    _ => null,
  };

  String? _decodeSvg(JsonSlice slice) {
    try {
      final v = slice.decode();
      return v is String ? v : null;
    } on FormatException catch (e) {
      debugPrint('lesson $id: diagram_svg unreadable ($e)');
      return null;
    }
  }
  final I18n? skipNote;
  final int contentVersion;

  String get moduleKey => '$track/$module';

  List<LessonSection> sections(ContentLang lang) => sectionsData.of(lang);
}

/// `sections` of a lesson (`{vi: [...], en: [...]}`): decoded, or kept as
/// a [JsonSlice] and decoded on every [of] (docs/07 §8). Sendable to an
/// isolate (the search index decodes there).
@immutable
class LessonSections {
  const LessonSections({
    required List<LessonSection> this._vi,
    required List<LessonSection> this._en,
  }) : _slice = null,
       _id = '';

  const LessonSections.lazy({
    required this._id,
    required JsonSlice this._slice,
  }) : _vi = null,
       _en = null;

  factory LessonSections.fromJson(Object? json) {
    final m = asMap(json, 'sections');
    return LessonSections(vi: _list(m, 'vi'), en: _list(m, 'en'));
  }

  static List<LessonSection> _list(JsonMap m, String lang) => List.unmodifiable(
    asList(m[lang], 'sections.$lang').map(LessonSection.fromJson),
  );

  final List<LessonSection>? _vi;
  final List<LessonSection>? _en;
  final JsonSlice? _slice;
  final String _id;

  /// A section list that does not decode (the build validates the schema,
  /// so only a damaged file) reads as empty rather than crashing the screen.
  List<LessonSection> of(ContentLang lang) {
    final slice = _slice;
    if (slice == null) return lang == ContentLang.vi ? _vi! : _en!;
    try {
      return _list(asMap(slice.decode(), 'sections'), lang.name);
    } on FormatException catch (e) {
      debugPrint('lesson $_id: sections unreadable ($e)');
      return const [];
    }
  }
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
