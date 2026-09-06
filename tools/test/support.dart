/// Shared fixture builders for the rule tests. Everything here is built
/// in-memory (no files written to content/, examples/, etc.) — ContentTree's
/// loader fields are public and mutable, so tests populate them directly
/// instead of going through ContentTree.load() against real repo files.
library test_support;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../src/content_tree.dart';
import '../src/glossary.dart';
import '../src/repo.dart';

/// Points at the real checked-out repo root, so tests can read the real
/// schemas/*.json (read-only) without writing anywhere outside a temp dir.
Repo realRepo() => Repo.find();

LessonEntry makeLesson({
  required String id,
  required String track,
  required int level,
  required int stage,
  required String moduleId,
  Map<String, dynamic>? title,
  bool mainPath = true,
  int durationMin = 10,
  List<String> skills = const [],
  List<String> prereqs = const [],
  List<String> related = const [],
  List<String> vocab = const [],
  String exampleTag = 'stage-1',
  List<String> exampleFiles = const [],
  List<String> outline = const ['a', 'b', 'c'],
  List<String> misconceptions = const ['m1', 'm2'],
  int globalOrder = -1,
}) {
  final raw = <String, dynamic>{
    'id': id,
    'title': title ?? {'vi': 'Tiêu đề $id', 'en': 'Title $id'},
    'main_path': mainPath,
    'duration_min': durationMin,
    'skills': skills,
    'prereqs': prereqs,
    'related': related,
    'vocab': vocab,
    'example_tag': exampleTag,
    'example_files': exampleFiles,
    'outline': outline,
    'misconceptions': misconceptions,
  };
  final lesson = LessonEntry(raw, track, level, moduleId, stage);
  lesson.globalOrder = globalOrder;
  return lesson;
}

/// A ContentTree with a golden lesson + its prereq + its related lesson
/// already registered, in global order prereq(0) < golden(1) < related(2).
class GoldenFixture {
  final ContentTree tree;
  final LessonEntry golden;
  final LessonEntry prereq;
  final LessonEntry related;
  GoldenFixture(this.tree, this.golden, this.prereq, this.related);
}

GoldenFixture buildGoldenTree() {
  final tree = ContentTree(realRepo());
  tree.pathYaml = {
    'stages': [
      {
        'stage': 1,
        'title': {'vi': 'x', 'en': 'x'},
        'gate': 'gate1',
        'modules': ['design/test-module']
      },
    ]
  };

  final prereq = makeLesson(
    id: 'design.l1.prereq-a',
    track: 'design',
    level: 1,
    stage: 1,
    moduleId: 'test-module',
    globalOrder: 0,
  );
  final golden = makeLesson(
    id: 'design.l1.golden-lesson',
    track: 'design',
    level: 1,
    stage: 1,
    moduleId: 'test-module',
    skills: ['design.test.skill'],
    prereqs: ['design.l1.prereq-a'],
    related: ['design.l1.related-a'],
    vocab: ['widget'],
    exampleTag: 'stage-1',
    exampleFiles: ['src/Widget.cs'],
    globalOrder: 1,
  );
  final related = makeLesson(
    id: 'design.l1.related-a',
    track: 'design',
    level: 1,
    stage: 1,
    moduleId: 'test-module',
    globalOrder: 2,
  );

  for (final l in [prereq, golden, related]) {
    tree.lessonsById[l.id] = l;
  }
  tree.modulesByKey['design/test-module'] = ModuleEntry('design', 'test-module', 1, [prereq, golden, related]);
  tree.skills.add(SkillEntry('design.test.skill', 'design', {'vi': 'x', 'en': 'x'}, []));
  tree.glossary.add(GlossaryEntry(
    term: 'widget',
    en: 'widget',
    viKeep: true,
    vi: 'widget',
    shortVi: 'mô tả ngắn',
    shortEn: 'short desc',
    introducedIn: golden.id,
    aliases: [],
  ));

  return GoldenFixture(tree, golden, prereq, related);
}

String _filler(int targetWords) {
  final sentences = <String>[];
  var words = 0;
  while (words < targetWords) {
    const s = 'This filler sentence exists only to reach the required word count for the fixture.';
    sentences.add(s);
    words += s.split(' ').length;
  }
  final buf = StringBuffer();
  for (int i = 0; i < sentences.length; i++) {
    buf.write(sentences[i]);
    buf.write(' ');
    if ((i + 1) % 5 == 0) buf.write('\n\n');
  }
  return buf.toString().trim();
}

/// A frontmatter map matching [GoldenFixture.golden] exactly (so L01's
/// track.yaml cross-check passes), and a body satisfying L02-L18 (level 1,
/// stage 1 -> "Beginners often think…", English).
Map<String, dynamic> goldenFrontmatter() => {
      'id': 'design.l1.golden-lesson',
      'lang': 'en',
      'track': 'design',
      'level': 1,
      'stage': 1,
      'module': 'test-module',
      'main_path': true,
      'title': 'Title design.l1.golden-lesson',
      'duration_min': 10,
      'skills': ['design.test.skill'],
      'prereqs': ['design.l1.prereq-a'],
      'related': ['design.l1.related-a'],
      'vocab': ['widget'],
      'example_tag': 'stage-1',
      'versions_used': <String>[],
      'content_version': 1,
      'status': 'draft',
    };

String goldenBody() {
  return '''
## Before you start

- [[design.l1.prereq-a]] — a made-up prerequisite lesson used only by this fixture.

## The situation

You are building a small screen for the Đơn Hàng admin panel and you keep repeating the same
button and label layout on every page, copying the same properties each time you add one, which
makes every small visual change require touching a dozen files instead of one, so what is a
better way to keep this consistent across the whole application?

## Core concepts

- **widget** — a small reusable UI element used throughout this fixture.
- layout — the arrangement of widgets on the screen.
- state — data that can change while a screen is visible.

## How it works

```mermaid
flowchart LR
  A[Start] --> B[Build]
  B --> C[Render]
```

${_filler(180)}

## In the Đơn Hàng system

```csharp file=src/Widget.cs tag=stage-1
public class Widget
{
    public string Label { get; set; }
}
```

## Beginners often think…

- **"A widget is only a visual thing."** → Actually a widget also owns behaviour and state, which is why it is a class and not just a picture.
- **"Copying a widget's code is faster than reusing it."** → Actually copies drift apart over time and each copy becomes its own bug source.

## Try it (3 minutes)

1. Open the fixture and change the widget's label once.

Expected result: the label changes everywhere the widget is reused.

${_filler(300)}

## Connections

- [[design.l1.related-a]] — the next fixture lesson, not real content.
- [[design.l1.prereq-a]] — the prerequisite fixture lesson again, for the link-count minimum.

${_filler(200)}

## Five-line summary

1. Widgets are reusable pieces that bundle a small piece of UI and its behaviour.
2. Extracting a widget once avoids repeating the same layout code everywhere.
3. State is the data a widget can change while it is visible.
4. Beginners often confuse a widget with a picture instead of a small class.
5. Reuse through a widget beats copy-pasting the same markup by hand.
''';
}

/// Writes [content] to a fresh file inside a temp dir and returns its path;
/// callers should delete the temp dir afterwards.
String writeTempFile(Directory dir, String relativePath, String content) {
  final file = File(p.join(dir.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  return file.path;
}
