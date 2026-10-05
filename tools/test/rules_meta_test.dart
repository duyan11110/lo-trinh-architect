import 'package:test/test.dart';

import '../src/errors.dart';
import '../src/rules_meta.dart';
import '../src/schema_validator.dart';
import 'support.dart';

Map<String, dynamic> validMeta({List<Map<String, dynamic>>? claims, Map<String, dynamic>? coverageOverrides, Map<String, dynamic>? selfCheckOverrides}) {
  return {
    'id': 'design.l1.golden-lesson',
    'generated_by': 'test',
    'generated_at': '2026-09-06T10:00:00+07:00',
    'claims': claims ??
        [
          {'n': 1, 'text': 'A specific, checkable statement about the fixture.', 'kind': 'fact', 'needs_verification': false},
          {'n': 2, 'text': 'Another checkable statement about the fixture.', 'kind': 'fact', 'needs_verification': false},
          {'n': 3, 'text': 'A third checkable statement about the fixture.', 'kind': 'fact', 'needs_verification': false},
        ],
    'coverage': {
      'outline_items_covered': [1, 2, 3],
      'outline_items_missing': <int>[],
      'beyond_scope': <String>[],
      ...?coverageOverrides,
    },
    'self_check': {
      'one_concept': true,
      'vocab_all_defined': true,
      'code_from_repo': true,
      'no_external_urls': true,
      'word_count': 950,
      ...?selfCheckOverrides,
    },
  };
}

void main() {
  test('M01: id in .meta.json does not match the lesson id', () {
    final meta = {...validMeta(), 'id': 'design.l1.wrong-id'};
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M01'), isTrue);
  });

  test('M01: fails schema when claims is empty', () {
    final meta = {...validMeta(), 'claims': <Map<String, dynamic>>[]};
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M01'), isTrue);
  });

  test('M02: outline_items_missing is non-empty', () {
    final meta = validMeta(coverageOverrides: {
      'outline_items_missing': [3]
    });
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M02'), isTrue);
  });

  test('M02: outline_items_covered does not equal 1..n', () {
    final fixture = buildGoldenTree(); // outline has 3 default items ['a','b','c']
    final meta = validMeta(coverageOverrides: {
      'outline_items_covered': [1, 2]
    });
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out, lesson: fixture.golden);
    expect(out.issues.any((i) => i.rule == 'M02'), isTrue);
  });

  test('M03: behavior/number/syntax/history claim without needs_verification:true', () {
    final meta = validMeta(claims: [
      {'n': 1, 'text': 'A behavior claim that forgot needs_verification.', 'kind': 'behavior', 'needs_verification': false, 'source_hint': 'x'},
      {'n': 2, 'text': 'Filler claim two for the fixture.', 'kind': 'fact', 'needs_verification': false},
      {'n': 3, 'text': 'Filler claim three for the fixture.', 'kind': 'fact', 'needs_verification': false},
    ]);
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M03'), isTrue);
  });

  test('M04: self_check.code_from_repo = false', () {
    final meta = validMeta(selfCheckOverrides: {'code_from_repo': false});
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M04'), isTrue);
  });

  test('M04: self_check.no_external_urls = false', () {
    final meta = validMeta(selfCheckOverrides: {'no_external_urls': false});
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M04'), isTrue);
  });

  test('M05: fewer than 3 claims when the lesson has a code block (warning)', () {
    final meta = validMeta(claims: [
      {'n': 1, 'text': 'Only one claim in a lesson that has code.', 'kind': 'fact', 'needs_verification': false},
    ]);
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M05' && i.level == Level.warning), isTrue);
  });

  test('M06: non-empty open_questions -> warning, printed', () {
    final meta = {...validMeta(), 'open_questions': ['Should we support X?']};
    final out = IssueCollector();
    validateMeta('design.l1.golden-lesson', meta, 1, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'M06' && i.level == Level.warning), isTrue);
  });
}
