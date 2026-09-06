import 'package:test/test.dart';

import '../src/errors.dart';
import '../src/rules_path.dart';
import '../src/schema_validator.dart';
import 'support.dart';

void main() {
  test('T01: path.yaml does not have exactly 5 stages', () {
    final fixture = buildGoldenTree();
    fixture.tree.pathYaml = {
      'stages': [
        {
          'stage': 0,
          'title': {'vi': 'x', 'en': 'x'},
          'gate': 'gate0',
          'modules': ['design/test-module']
        },
      ]
    };
    final out = IssueCollector();
    validatePath(fixture.tree, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'T01'), isTrue);
  });

  test('T01: the same module listed under two different stages', () {
    final fixture = buildGoldenTree();
    fixture.tree.pathYaml = {
      'stages': [
        for (final s in [0, 1, 2, 3, 4])
          {
            'stage': s,
            'title': {'vi': 'x', 'en': 'x'},
            'gate': 'gate$s',
            'modules': s <= 1 ? ['design/test-module'] : ['design/other-$s'],
          }
      ]
    };
    final out = IssueCollector();
    validatePath(fixture.tree, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'T01' && i.id == 'path.yaml'), isTrue);
  });

  test('T02: a main_path lesson has a branch (main_path:false) prereq', () {
    final fixture = buildGoldenTree();
    fixture.prereq.raw['main_path'] = false;
    final out = IssueCollector();
    validatePath(fixture.tree, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'T02' && i.id == fixture.golden.id), isTrue);
  });

  test('T03: module stage in track.yaml differs from path.yaml', () {
    final fixture = buildGoldenTree();
    // golden fixture's module is stage 1 in track.yaml; make path.yaml disagree.
    fixture.tree.pathYaml = {
      'stages': [
        for (final s in [0, 1, 2, 3, 4])
          {
            'stage': s,
            'title': {'vi': 'x', 'en': 'x'},
            'gate': 'gate$s',
            'modules': s == 2 ? ['design/test-module'] : ['design/other-$s'],
          }
      ]
    };
    fixture.tree.moduleStageInPath['design/test-module'] = 2; // path.yaml says stage 2
    final out = IssueCollector();
    validatePath(fixture.tree, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'T03' && i.id == 'design/test-module'), isTrue);
  });
}
