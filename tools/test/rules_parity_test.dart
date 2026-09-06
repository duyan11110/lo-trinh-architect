import 'package:test/test.dart';

import '../src/errors.dart';
import '../src/glossary.dart';
import '../src/rules_parity.dart';
import 'support.dart';

Map<String, dynamic> _fmEn() => {...goldenFrontmatter(), 'lang': 'en', 'title': 'English title'};
Map<String, dynamic> _fmVi() => {...goldenFrontmatter(), 'lang': 'vi', 'title': 'Tiêu đề tiếng Việt'};

void main() {
  test('a byte-identical-shape EN/VI pair has no parity errors', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['title'] = {'vi': 'Tiêu đề tiếng Việt', 'en': 'English title'};
    final bodyEn = goldenBody();
    final bodyVi = goldenBody(); // same shape (headings/links/code counts), content is irrelevant here
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), bodyEn, _fmVi(), bodyVi, fixture.golden, fixture.tree, out);
    expect(out.hasErrors, isFalse);
  });

  test('P01: frontmatter differs on a field other than lang/title', () {
    final fixture = buildGoldenTree();
    final bodyEn = goldenBody();
    final bodyVi = goldenBody();
    final fmVi = {..._fmVi(), 'duration_min': 99};
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), bodyEn, fmVi, bodyVi, fixture.golden, fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'P01'), isTrue);
  });

  test('P01: VI title does not match track.yaml title.vi', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['title'] = {'vi': 'Tiêu đề đúng', 'en': 'English title'};
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), goldenBody(), _fmVi(), goldenBody(), fixture.golden,
        fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'P01'), isTrue);
  });

  test('P02: different number of H2 sections between EN and VI', () {
    final fixture = buildGoldenTree();
    final bodyVi = goldenBody().replaceFirst('## Five-line summary', '## Extra section\n\ntext\n\n## Five-line summary');
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), goldenBody(), _fmVi(), bodyVi, fixture.golden, fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'P02'), isTrue);
  });

  test('P02: different number of [[id]] links', () {
    final fixture = buildGoldenTree();
    final bodyVi = goldenBody().replaceFirst('[[design.l1.related-a]]', '[[design.l1.related-a]] [[design.l1.prereq-a]]');
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), goldenBody(), _fmVi(), bodyVi, fixture.golden, fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'P02'), isTrue);
  });

  test('P03: vi_keep:true term missing its English spelling in the VI body', () {
    final fixture = buildGoldenTree();
    fixture.tree.glossary.clear();
    fixture.tree.glossary.add(GlossaryEntry(
      term: 'widget',
      en: 'widget',
      viKeep: true,
      vi: 'widget',
      shortVi: 'x',
      shortEn: 'x',
      introducedIn: fixture.golden.id,
      aliases: const [],
    ));
    final bodyVi = goldenBody().replaceAll(RegExp('widget', caseSensitive: false), 'phan-tu-giao-dien');
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), goldenBody(), _fmVi(), bodyVi, fixture.golden, fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'P03'), isTrue);
  });

  test('P04: VI body contains "một cách" (warning)', () {
    final fixture = buildGoldenTree();
    final bodyVi = '${goldenBody()}\n\nĐiều này được làm một cách cẩn thận.';
    final out = IssueCollector();
    validateParity('design.l1.golden-lesson', _fmEn(), goldenBody(), _fmVi(), bodyVi, fixture.golden, fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'P04' && i.level == Level.warning), isTrue);
  });
}
