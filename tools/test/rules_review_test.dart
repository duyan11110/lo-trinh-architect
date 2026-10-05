import 'package:test/test.dart';

import '../src/errors.dart';
import '../src/rules_review.dart';
import '../src/schema_validator.dart';
import 'support.dart';

final claims = [
  {'n': 1, 'text': 'A claim that needs verification.', 'kind': 'behavior', 'needs_verification': true},
  {'n': 2, 'text': 'A plain fact claim.', 'kind': 'fact', 'needs_verification': false},
];

Map<String, dynamic> passingReview({String technicalVerdict = 'pass', String juniorVerdict = 'pass', List<Map<String, dynamic>>? claimVerdicts, List<Map<String, dynamic>>? techIssues, List<Map<String, dynamic>>? juniorIssues}) {
  return {
    'id': 'design.l1.golden-lesson',
    'technical': {
      'reviewed_at': '2026-09-06T10:00:00+07:00',
      'reviewer': 'test',
      'claim_verdicts': claimVerdicts ??
          [
            {'n': 1, 'verdict': 'verified', 'evidence': 'Checked against the official docs directly.'},
            {'n': 2, 'verdict': 'not-needed', 'evidence': 'Plain fact, no source needed here.'},
          ],
      'issues': techIssues ?? <Map<String, dynamic>>[],
      'scope': {'outline_covered': true, 'beyond_scope': <String>[]},
      'verdict': technicalVerdict,
    },
    'junior': {
      'reviewed_at': '2026-09-06T10:00:00+07:00',
      'reviewer': 'test',
      'issues': juniorIssues ?? <Map<String, dynamic>>[],
      'readability': {
        'unknown_terms': <String>[],
        'skipped_steps': <String>[],
        'situation_connects': true,
        'try_it_feasible': true,
        'summary_matches': true,
      },
      'verdict': juniorVerdict,
    },
  };
}

void main() {
  test('R01: .review.json missing while status >= reviewed', () {
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', null, 'reviewed', claims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R01' && i.level == Level.error), isTrue);
  });

  test('R01: .review.json missing while status draft -> no issue', () {
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', null, 'draft', claims, SchemaValidator(realRepo()), out);
    expect(out.issues, isEmpty);
  });

  test('R01: review present but missing "junior" section at status reviewed', () {
    final review = passingReview();
    review.remove('junior');
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'reviewed', claims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R01'), isTrue);
  });

  test('R02: claim needs_verification:true has no verdict', () {
    final review = passingReview(claimVerdicts: [
      {'n': 2, 'verdict': 'not-needed', 'evidence': 'Plain fact, no source needed here.'},
    ]);
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'reviewed', claims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R02'), isTrue);
  });

  test('R03: an open blocker at status reviewed', () {
    final review = passingReview(techIssues: [
      {'severity': 'blocker', 'section': 4, 'kind': 'accuracy', 'text': 'A blocking accuracy problem found.', 'fix': 'Rewrite the paragraph to say X instead.'}
    ]);
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'reviewed', claims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R03'), isTrue);
  });

  test('R03: an open major at status approved', () {
    final review = passingReview(juniorIssues: [
      {'severity': 'major', 'section': 3, 'kind': 'term', 'text': 'Uses a term the reader has not learned yet.', 'fix': 'Define the term or move it to vocab.'}
    ]);
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'approved', claims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R03'), isTrue);
  });

  test('R04: a claim verdict is "wrong" at status reviewed', () {
    final review = passingReview(claimVerdicts: [
      {'n': 1, 'verdict': 'wrong', 'evidence': 'Directly contradicted by the official docs.'},
      {'n': 2, 'verdict': 'not-needed', 'evidence': 'Plain fact, no source needed here.'},
    ]);
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'reviewed', claims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R04'), isTrue);
  });

  test('R04: unverified number/syntax claim not allowed at approved', () {
    final numberClaims = [
      {'n': 1, 'text': 'A numeric limit claim for the fixture.', 'kind': 'number', 'needs_verification': true},
    ];
    final review = passingReview(claimVerdicts: [
      {'n': 1, 'verdict': 'unverified', 'evidence': 'Could not find a documented value for this.'},
    ]);
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'approved', numberClaims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R04' && i.level == Level.error), isTrue);
  });

  test('R04: unverified behavior/fact claim allowed at approved, but warned', () {
    final behaviorClaims = [
      {'n': 1, 'text': 'A behavior claim for the fixture.', 'kind': 'behavior', 'needs_verification': true},
    ];
    final review = passingReview(claimVerdicts: [
      {'n': 1, 'verdict': 'unverified', 'evidence': 'Could not verify against available docs.'},
    ]);
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'approved', behaviorClaims, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'R04' && i.level == Level.error), isFalse);
    expect(out.issues.any((i) => i.rule == 'R04' && i.level == Level.warning), isTrue);
  });

  test('a clean review at approved has no errors', () {
    final review = passingReview();
    final out = IssueCollector();
    validateReview('design.l1.golden-lesson', review, 'approved', claims, SchemaValidator(realRepo()), out);
    expect(out.hasErrors, isFalse);
  });
}
