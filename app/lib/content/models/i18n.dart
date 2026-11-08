// Shared JSON helpers and the bilingual string type used across
// content.json (schemas/content.schema.json `$defs/i18n`).
import 'package:flutter/foundation.dart';

/// Content language. Lessons are written in both (`meta.langs`).
enum ContentLang {
  vi,
  en;

  static ContentLang fromCode(String? code) =>
      code == 'en' ? ContentLang.en : ContentLang.vi;
}

/// `{ "vi": "...", "en": "..." }`.
@immutable
class I18n {
  const I18n({required this.vi, required this.en});

  factory I18n.fromJson(Object? json) {
    final m = asMap(json, 'i18n');
    return I18n(vi: m.str('vi'), en: m.str('en'));
  }

  final String vi;
  final String en;

  String of(ContentLang lang) => lang == ContentLang.vi ? vi : en;

  @override
  bool operator ==(Object other) =>
      other is I18n && other.vi == vi && other.en == en;

  @override
  int get hashCode => Object.hash(vi, en);
}

typedef JsonMap = Map<String, Object?>;

JsonMap asMap(Object? json, String what) {
  if (json is Map<String, Object?>) return json;
  if (json is Map) return json.cast<String, Object?>();
  throw FormatException('content.json: expected object for $what');
}

List<Object?> asList(Object? json, String what) {
  if (json is List) return json;
  throw FormatException('content.json: expected array for $what');
}

extension JsonMapRead on JsonMap {
  Object? _req(String key) {
    if (!containsKey(key)) {
      throw FormatException('content.json: missing "$key"');
    }
    return this[key];
  }

  String str(String key) {
    final v = _req(key);
    if (v is String) return v;
    throw FormatException('content.json: "$key" must be a string');
  }

  String? strOrNull(String key) {
    final v = this[key];
    return v is String ? v : null;
  }

  int integer(String key) {
    final v = _req(key);
    if (v is int) return v;
    if (v is num && v == v.roundToDouble()) return v.toInt();
    throw FormatException('content.json: "$key" must be an integer');
  }

  int? intOrNull(String key) {
    final v = this[key];
    return v is num ? v.toInt() : null;
  }

  bool boolean(String key) {
    final v = _req(key);
    if (v is bool) return v;
    throw FormatException('content.json: "$key" must be a boolean');
  }

  List<String> strings(String key) =>
      List.unmodifiable(asList(_req(key), key).cast<String>());

  List<String> stringsOrEmpty(String key) => containsKey(key)
      ? List.unmodifiable(asList(this[key], key).cast<String>())
      : const [];

  I18n i18n(String key) => I18n.fromJson(_req(key));

  I18n? i18nOrNull(String key) =>
      this[key] == null ? null : I18n.fromJson(this[key]);

  List<T> list<T>(String key, T Function(Object? json) item) =>
      List.unmodifiable(asList(_req(key), key).map(item));
}
