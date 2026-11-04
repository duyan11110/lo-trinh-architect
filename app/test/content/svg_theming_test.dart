// docs/07 §6: sentinel colours → theme tokens, cached per (lesson, brightness).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/app/theme/tokens.dart';
import 'package:lta_app/content/svg_theming.dart';

void main() {
  const svg =
      '<svg font-family="Be Vietnam Pro, sans-serif"><rect fill="#020202" '
      'stroke="#030303"/><text fill="#010101">x</text></svg>';

  test('sentinels become ink / surface2 / line of the theme', () {
    final light = themeSvg(svg, LtaColors.light);
    expect(light, contains('fill="#eef1f8"'));
    expect(light, contains('stroke="#d9deeb"'));
    expect(light, contains('fill="#17203a"'));
    expect(light, isNot(contains('#01010')));
    expect(light, contains('font-family="${LtaFont.sans}, sans-serif"'));
    expect(themeSvg(svg, LtaColors.dark), contains('fill="#e8ebf5"'));
  });

  test('cache keyed by (lesson, brightness)', () {
    final cache = SvgThemeCache();
    final a = cache.get('l', Brightness.light, svg, LtaColors.light);
    final b = cache.get('l', Brightness.dark, svg, LtaColors.dark);
    expect(a, isNot(b));
    expect(cache.get('l', Brightness.light, svg, LtaColors.dark), a);
  });
}
