// SVG theming — docs/07 §6. `tools/build` emits three sentinel colours; the
// app swaps them for the current theme's tokens before `SvgPicture.string`.
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';

abstract final class SvgSentinel {
  static const ink = '#010101';
  static const surface2 = '#020202';
  static const line = '#030303';
}

String _hex(Color c) {
  final argb = c.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Font family name `tools/build` writes into every SVG.
const _buildFontFamily = 'Be Vietnam Pro';

/// Replaces the sentinels: `#010101 → ink`, `#020202 → surface2`,
/// `#030303 → line`. Also maps the build's font family onto the family
/// bundled in pubspec ([LtaFont.sans]); otherwise flutter_svg falls back to
/// the platform default font.
String themeSvg(String svg, LtaColors c) => svg
    .replaceAll(_buildFontFamily, LtaFont.sans)
    .replaceAll(RegExp(SvgSentinel.ink, caseSensitive: false), _hex(c.ink))
    .replaceAll(
      RegExp(SvgSentinel.surface2, caseSensitive: false),
      _hex(c.surface2),
    )
    .replaceAll(RegExp(SvgSentinel.line, caseSensitive: false), _hex(c.line));

/// Cache keyed by `(lesson id, brightness)` (docs/07 §6).
class SvgThemeCache {
  SvgThemeCache({this.capacity = 20});

  final int capacity;
  // Insertion-ordered map literal doubles as an LRU.
  final _cache = <(String, Brightness), String>{};

  String get(String lessonId, Brightness b, String svg, LtaColors c) {
    final key = (lessonId, b);
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    final themed = themeSvg(svg, c);
    _cache[key] = themed;
    if (_cache.length > capacity) _cache.remove(_cache.keys.first);
    return themed;
  }

  void clear() => _cache.clear();
}
