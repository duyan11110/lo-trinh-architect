// `glossary[]` of content.json (glossary.yaml verbatim).
import 'package:flutter/foundation.dart';

import 'i18n.dart';

@immutable
class GlossaryEntry {
  const GlossaryEntry({
    required this.term,
    required this.en,
    required this.viKeep,
    required this.vi,
    required this.shortVi,
    required this.shortEn,
    required this.introducedIn,
    this.aliases = const [],
  });

  factory GlossaryEntry.fromJson(Object? json) {
    final m = asMap(json, 'glossary[]');
    return GlossaryEntry(
      term: m.str('term'),
      en: m.str('en'),
      viKeep: m.boolean('vi_keep'),
      vi: m.str('vi'),
      shortVi: m.str('short_vi'),
      shortEn: m.str('short_en'),
      introducedIn: m.str('introduced_in'),
      aliases: m.stringsOrEmpty('aliases'),
    );
  }

  /// Slug, e.g. `status-code`.
  final String term;
  final String en;
  final bool viKeep;
  final String vi;
  final String shortVi;
  final String shortEn;

  /// Lesson id that teaches the term ("Học ở").
  final String introducedIn;
  final List<String> aliases;

  /// Display name in [lang] (`vi` keeps the English term when [viKeep]).
  String name(ContentLang lang) => lang == ContentLang.en ? en : vi;

  String short(ContentLang lang) => lang == ContentLang.en ? shortEn : shortVi;
}
