import 'package:test/test.dart';

import '../src/code_source.dart';
import '../src/errors.dart';
import '../src/glossary.dart';
import '../src/rules_lesson.dart';
import '../src/schema_validator.dart';
import 'support.dart';

CodeSource _codeSourceWithFile(Map<String, String> files) {
  return _FakeCodeSource(files);
}

/// A CodeSource that answers from an in-memory map instead of the filesystem,
/// so L08/L08b tests don't need git or a real repo-dir.
class _FakeCodeSource implements CodeSource {
  final Map<String, String> files; // "tag:path" -> content
  _FakeCodeSource(this.files);

  @override
  String? get repoDir => null;

  @override
  bool get isRepoDirMode => true; // treat missing-file as a warning, like --repo-dir

  @override
  String get gitRepoPath => '';

  @override
  bool tagExists(String tag) => true;

  @override
  bool fileExists(String tag, String relativePath) => files.containsKey('$tag:$relativePath');

  @override
  String? readFile(String tag, String relativePath) => files['$tag:$relativePath'];
}

List<Issue> _run(String body, {Map<String, dynamic>? fmOverrides, CodeSource? codeSource}) {
  final fixture = buildGoldenTree();
  final fm = {...goldenFrontmatter(), ...?fmOverrides};
  final sv = SchemaValidator(realRepo());
  final out = IssueCollector();
  final input = LessonValidationInput(
    id: fm['id'] as String,
    frontmatter: fm,
    body: body,
    tree: fixture.tree,
    codeSource: codeSource ??
        _codeSourceWithFile({
          'stage-1:src/Widget.cs': 'public class Widget\n{\n    public string Label { get; set; }\n}',
        }),
  );
  validateLesson(input, sv, out);
  return out.issues;
}

bool _has(List<Issue> issues, String rule) => issues.any((i) => i.rule == rule);

void main() {
  test('golden fixture has no L-rule errors', () {
    final issues = _run(goldenBody());
    final errors = issues.where((i) => i.level == Level.error).toList();
    expect(errors, isEmpty, reason: errors.map((e) => e.toString()).join('\n'));
  });

  test('L01: frontmatter fails schema when a field is out of range', () {
    final issues = _run(goldenBody(), fmOverrides: {'duration_min': 3});
    expect(_has(issues, 'L01'), isTrue);
  });

  test('L01: title mismatch with track.yaml', () {
    final issues = _run(goldenBody(), fmOverrides: {'title': 'Wrong title entirely'});
    expect(_has(issues, 'L01'), isTrue);
  });

  test('L02: wrong H2 heading order/text', () {
    final body = goldenBody().replaceFirst('## The situation', '## Wrong Heading');
    final issues = _run(body);
    expect(_has(issues, 'L02'), isTrue);
  });

  test('L03: main_path:false lesson missing the Skip blockquote', () {
    final issues = _run(goldenBody(), fmOverrides: {'main_path': false});
    expect(_has(issues, 'L03'), isTrue);
  });

  test('L03: main_path:true lesson must not have the Skip blockquote', () {
    final body = '> Skip this if: you already know this.\n\n${goldenBody()}';
    final issues = _run(body);
    expect(_has(issues, 'L03'), isTrue);
  });

  test('L04: bullet count in "Before you start" does not match prereqs', () {
    final body = goldenBody().replaceFirst(
      '- [[design.l1.prereq-a]] — a made-up prerequisite lesson used only by this fixture.',
      '- [[design.l1.prereq-a]] — one.\n- [[design.l1.related-a]] — two, not a real prereq.',
    );
    final issues = _run(body);
    expect(_has(issues, 'L04'), isTrue);
  });

  test('L05: situation section too short', () {
    final body = goldenBody().replaceFirst(
      RegExp(r'## The situation\n\n[\s\S]*?\n\n## Core concepts'),
      '## The situation\n\nToo short to pass the word count and not even a question.\n\n## Core concepts',
    );
    final issues = _run(body);
    expect(_has(issues, 'L05'), isTrue);
  });

  test('L06: vocab term not bolded exactly once in Core concepts', () {
    final body = goldenBody().replaceFirst('**widget**', 'widget');
    final issues = _run(body);
    expect(_has(issues, 'L06'), isTrue);
  });

  test('L07: missing mermaid block', () {
    final body = goldenBody().replaceFirst(RegExp(r'```mermaid[\s\S]*?```\n\n'), '');
    final issues = _run(body);
    expect(_has(issues, 'L07'), isTrue);
  });

  test('L08: code block exceeds 25 lines', () {
    final longCode = List.generate(30, (i) => '    // line $i').join('\n');
    final body = goldenBody().replaceFirst(
      'public class Widget\n{\n    public string Label { get; set; }\n}',
      'public class Widget\n{\n$longCode\n}',
    );
    final issues = _run(body);
    expect(_has(issues, 'L08'), isTrue);
  });

  test('L08: file= not in example_files', () {
    final body = goldenBody().replaceFirst('file=src/Widget.cs', 'file=src/Other.cs');
    final issues = _run(body, codeSource: _codeSourceWithFile({
      'stage-1:src/Other.cs': 'public class Widget\n{\n    public string Label { get; set; }\n}',
    }));
    expect(_has(issues, 'L08'), isTrue);
  });

  test('L08: code content does not match the repo file', () {
    final issues = _run(goldenBody(), codeSource: _codeSourceWithFile({
      'stage-1:src/Widget.cs': 'public class SomethingElse {}',
    }));
    expect(_has(issues, 'L08'), isTrue);
  });

  test('L08b: output block not immediately after a file= block', () {
    final body = goldenBody().replaceFirst(
      '```csharp file=src/Widget.cs tag=stage-1',
      '```text output=true\nsome output\n```\n\n```csharp file=src/Widget.cs tag=stage-1',
    );
    final issues = _run(body);
    expect(_has(issues, 'L08b'), isTrue);
  });

  test('L09: misconception bullet missing the quote/arrow pattern', () {
    final body = goldenBody().replaceFirst(
      '- **"A widget is only a visual thing."** → Actually a widget also owns behaviour and state, which is why it is a class and not just a picture.',
      '- A widget is just a visual thing, actually it also has behaviour.',
    );
    final issues = _run(body);
    expect(_has(issues, 'L09'), isTrue);
  });

  test('L10: Try it section missing "Expected result:"', () {
    final body = goldenBody().replaceFirst('Expected result: the label changes everywhere the widget is reused.', '');
    final issues = _run(body);
    expect(_has(issues, 'L10'), isTrue);
  });

  test('L11: Connections section has fewer than 2 links', () {
    final body = goldenBody().replaceFirst(
      '- [[design.l1.related-a]] — the next fixture lesson, not real content.\n- [[design.l1.prereq-a]] — the prerequisite fixture lesson again, for the link-count minimum.',
      '- [[design.l1.related-a]] — only one link here.',
    );
    final issues = _run(body);
    expect(_has(issues, 'L11'), isTrue);
  });

  test('L12: summary section does not have exactly 5 numbered lines', () {
    final body = goldenBody().replaceFirst(
      '5. Reuse through a widget beats copy-pasting the same markup by hand.',
      '5. Reuse through a widget beats copy-pasting the same markup by hand.\n6. One line too many.',
    );
    final issues = _run(body);
    expect(_has(issues, 'L12'), isTrue);
  });

  test('L13: total word count below the minimum', () {
    final shortBody = goldenBody().replaceAll(RegExp(r'This filler sentence[^\n]*\n?'), '');
    final issues = _run(shortBody);
    expect(_has(issues, 'L13'), isTrue);
  });

  test('L14: URL in the body', () {
    final body = goldenBody().replaceFirst(
      'a small reusable UI element',
      'a small reusable UI element (see https://example.com/widgets)',
    );
    final issues = _run(body);
    expect(_has(issues, 'L14'), isTrue);
  });

  test('L15: uses a glossary term outside known_vocab ∪ vocab (warning)', () {
    final fixture = buildGoldenTree();
    fixture.tree.glossary.add(GlossaryEntry(
      term: 'middleware',
      en: 'middleware',
      viKeep: true,
      vi: 'middleware',
      shortVi: 'x',
      shortEn: 'x',
      introducedIn: 'design.l1.related-a',
      aliases: const [],
    ));
    final body = goldenBody().replaceFirst(
      'a small reusable UI element',
      'a small reusable UI element, similar to middleware in spirit',
    );
    final sv = SchemaValidator(realRepo());
    final out = IssueCollector();
    final input = LessonValidationInput(
      id: 'design.l1.golden-lesson',
      frontmatter: goldenFrontmatter(),
      body: body,
      tree: fixture.tree,
      codeSource: _codeSourceWithFile({
        'stage-1:src/Widget.cs': 'public class Widget\n{\n    public string Label { get; set; }\n}',
      }),
    );
    validateLesson(input, sv, out);
    expect(out.issues.any((i) => i.rule == 'L15' && i.level == Level.warning), isTrue);
  });

  test('L16: bold text that is not a vocab term (warning)', () {
    final body = goldenBody().replaceFirst(
      'layout — the arrangement',
      '**layout** — the arrangement',
    );
    final issues = _run(body);
    expect(issues.any((i) => i.rule == 'L16' && i.level == Level.warning), isTrue);
  });

  test('L17: forbidden phrase "recently"', () {
    final body = goldenBody().replaceFirst(
      'a small reusable UI element',
      'a small reusable UI element added recently',
    );
    final issues = _run(body);
    expect(_has(issues, 'L17'), isTrue);
  });

  test('L18: paragraph with more than 6 sentences', () {
    final longPara =
        'One. Two. Three. Four. Five. Six. Seven. Eight sentences in a single paragraph, on purpose.';
    final body = goldenBody().replaceFirst(
      'Expected result: the label changes everywhere the widget is reused.',
      'Expected result: the label changes everywhere the widget is reused.\n\n$longPara',
    );
    final issues = _run(body);
    expect(_has(issues, 'L18'), isTrue);
  });
}
