import 'package:test/test.dart';

import '../src/svg_theming.dart';

void main() {
  test('strips <style> and <foreignObject>, and inlines class-based CSS onto the element', () {
    const raw = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <style>
    .node { fill: #020202; stroke: #030303; }
  </style>
  <rect class="node" x="0" y="0" width="10" height="10"></rect>
  <foreignObject x="0" y="0" width="10" height="10"><div>label</div></foreignObject>
  <rect fill="#ffffff" width="100" height="100"></rect>
</svg>
''';
    final out = postprocessMermaidSvg(raw);

    expect(out.contains('<style'), isFalse);
    expect(out.contains('</style>'), isFalse);
    expect(out.contains('<foreignObject'), isFalse);
    expect(out.contains('fill="#020202"'), isTrue);
    expect(out.contains('stroke="#030303"'), isTrue);
    expect(out.toLowerCase().contains('fill="#ffffff"'), isFalse);
    expect(out.contains('font-family="Be Vietnam Pro, sans-serif"'), isTrue);
  });
}
