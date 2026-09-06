import 'dart:io';

import 'package:test/test.dart';

import '../src/content_tree.dart';
import '../src/errors.dart';
import '../src/glossary.dart';
import '../src/rules_structure.dart';
import '../src/schema_validator.dart';
import 'support.dart';

void main() {
  test('S01: track.yaml fails schema (missing required "title")', () {
    final tree = ContentTree(realRepo());
    tree.pathYaml = {'stages': []};
    tree.trackYamls['foundation'] = {
      'id': 'foundation',
      // 'title' intentionally missing
      'description': {'vi': 'x', 'en': 'x'},
      'skills': [],
      'levels': [],
    };
    final out = IssueCollector();
    checkS01TrackSchemas(tree, SchemaValidator(realRepo()), out);
    expect(out.issues.any((i) => i.rule == 'S01' && i.level == Level.error), isTrue);
  });

  test('S02: duplicate lesson id across track.yaml', () {
    final tree = ContentTree(realRepo());
    tree.pathYaml = {'stages': []};
    Map<String, dynamic> lessonRaw(String id) => {
          'id': id,
          'title': {'vi': 'x', 'en': 'x'},
          'main_path': true,
          'duration_min': 10,
          'skills': <String>[],
          'prereqs': <String>[],
          'related': <String>[],
          'vocab': <String>[],
          'example_tag': 'stage-1',
          'outline': ['a', 'b', 'c'],
          'misconceptions': ['a', 'b'],
        };
    tree.trackYamls['design'] = {
      'id': 'design',
      'levels': [
        {
          'level': 1,
          'modules': [
            {
              'id': 'mod-a',
              'stage': 1,
              'lessons': [lessonRaw('design.l1.dup')]
            },
            {
              'id': 'mod-b',
              'stage': 1,
              'lessons': [lessonRaw('design.l1.dup')]
            },
          ]
        }
      ]
    };
    final out = IssueCollector();
    checkS02DuplicateIds(tree, out);
    expect(out.issues.any((i) => i.rule == 'S02' && i.level == Level.error), isTrue);
  });

  test('S03: module in track.yaml but not in path.yaml -> error', () {
    final fixture = buildGoldenTree();
    fixture.tree.trackOnlyModules.add('design/test-module');
    final out = IssueCollector();
    checkS03ModulePresence(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S03' && i.level == Level.error), isTrue);
  });

  test('S03: module in path.yaml but not yet outlined -> warning', () {
    final fixture = buildGoldenTree();
    fixture.tree.pathOnlyModules.add('backend/not-yet-outlined');
    fixture.tree.moduleStageInPath['backend/not-yet-outlined'] = 1;
    final out = IssueCollector();
    checkS03ModulePresence(fixture.tree, out);
    expect(
        out.issues.any((i) =>
            i.rule == 'S03' && i.level == Level.warning && i.id == 'backend/not-yet-outlined'),
        isTrue);
  });

  test('S04: prereq id does not exist', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['prereqs'] = ['design.l1.does-not-exist'];
    final out = IssueCollector();
    checkS04Prereqs(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S04' && i.id == fixture.golden.id), isTrue);
  });

  test('S04: prereq has global order >= current lesson', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['prereqs'] = ['design.l1.related-a']; // related-a has a *later* order
    final out = IssueCollector();
    checkS04Prereqs(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S04' && i.id == fixture.golden.id), isTrue);
  });

  test('S05: skill does not exist in any track.yaml', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['skills'] = ['design.no.such.skill'];
    final out = IssueCollector();
    checkS05Skills(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S05' && i.id == fixture.golden.id), isTrue);
  });

  test('S06: vocab term not in glossary.yaml', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['vocab'] = ['no-such-term'];
    final out = IssueCollector();
    checkS06Vocab(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S06' && i.id == fixture.golden.id), isTrue);
  });

  test('S06: vocab term already declared by an earlier lesson', () {
    final fixture = buildGoldenTree();
    // prereq (earlier global order) also declares "widget"
    fixture.prereq.raw['vocab'] = ['widget'];
    final out = IssueCollector();
    checkS06Vocab(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S06' && i.id == fixture.golden.id), isTrue);
  });

  test('S06: glossary.introduced_in mismatch', () {
    final fixture = buildGoldenTree();
    fixture.tree.glossary.clear();
    fixture.tree.glossary.add(GlossaryEntry(
      term: 'widget',
      en: 'widget',
      viKeep: true,
      vi: 'widget',
      shortVi: 'x',
      shortEn: 'x',
      introducedIn: 'design.l1.related-a', // wrong: should be golden.id
      aliases: const [],
    ));
    final out = IssueCollector();
    checkS06Vocab(fixture.tree, out);
    expect(out.issues.any((i) => i.rule == 'S06' && i.id == fixture.golden.id), isTrue);
  });

  test('S07: --repo-dir missing example file -> warning, not error', () {
    final fixture = buildGoldenTree();
    final tmp = Directory.systemTemp.createTempSync('lta_s07_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    // repoDir exists but does NOT contain src/Widget.cs
    final out = IssueCollector();
    checkS07ExampleFiles(fixture.tree, realRepo(), out, repoDir: tmp.path);
    expect(
        out.issues.any((i) =>
            i.rule == 'S07' && i.level == Level.warning && i.id == fixture.golden.id),
        isTrue);
    expect(out.hasErrors, isFalse);
  });

  test('S07: --repo-dir has the file -> no issue', () {
    final fixture = buildGoldenTree();
    final tmp = Directory.systemTemp.createTempSync('lta_s07_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    Directory('${tmp.path}/src').createSync(recursive: true);
    File('${tmp.path}/src/Widget.cs').writeAsStringSync('public class Widget {}');
    final out = IssueCollector();
    checkS07ExampleFiles(fixture.tree, realRepo(), out, repoDir: tmp.path);
    expect(out.issues.where((i) => i.id == fixture.golden.id), isEmpty);
  });

  test('S08: related id not outlined -> warning, not error', () {
    final fixture = buildGoldenTree();
    fixture.golden.raw['related'] = ['design.l1.not-outlined-yet'];
    final out = IssueCollector();
    checkS08Related(fixture.tree, out);
    expect(
        out.issues.any((i) =>
            i.rule == 'S08' && i.level == Level.warning && i.id == fixture.golden.id),
        isTrue);
  });
}
