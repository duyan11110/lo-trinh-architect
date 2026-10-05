/// S01–S08 — structural rules (track.yaml / path.yaml / glossary.yaml consistency).
library rules_structure;

import 'dart:io';
import 'package:path/path.dart' as p;

import 'content_tree.dart';
import 'errors.dart';
import 'repo.dart';
import 'schema_validator.dart';

void checkS01TrackSchemas(ContentTree tree, SchemaValidator sv, IssueCollector out) {
  for (final entry in tree.trackYamls.entries) {
    final trackId = entry.key;
    final errs = sv.validate('track.schema.json', entry.value);
    for (final e in errs) {
      out.error(trackId, 'S01', 'track.yaml không qua schema: $e');
    }
  }
}

void checkS02DuplicateIds(ContentTree tree, IssueCollector out) {
  final seen = <String, int>{};
  for (final lesson in tree.lessonsById.values) {
    seen[lesson.id] = (seen[lesson.id] ?? 0) + 1;
  }
  // lessonsById is already a Map keyed by id so true duplicates across tracks
  // are only detectable if two different LessonEntry objects share an id,
  // which the map construction itself would have silently overwritten.
  // Re-scan the raw track ASTs to catch that case.
  final idCounts = <String, int>{};
  for (final trackId in tree.trackYamls.keys) {
    final raw = tree.trackYamls[trackId]!;
    for (final levelRaw in (raw['levels'] as List? ?? [])) {
      for (final modRaw in ((levelRaw as Map)['modules'] as List? ?? [])) {
        for (final lessonRaw in ((modRaw as Map)['lessons'] as List? ?? [])) {
          final id = (lessonRaw as Map)['id'] as String;
          idCounts[id] = (idCounts[id] ?? 0) + 1;
        }
      }
    }
  }
  for (final e in idCounts.entries) {
    if (e.value > 1) {
      out.error(e.key, 'S02', 'lesson id trùng (${e.value} lần) trong content/tracks/');
    }
  }
}

void checkS03ModulePresence(ContentTree tree, IssueCollector out, {int? stageFilter}) {
  for (final key in tree.pathOnlyModules) {
    final stage = tree.moduleStageInPath[key];
    if (stageFilter != null && stage != stageFilter) continue;
    out.warn(key, 'S03', 'module có trong path.yaml nhưng chưa có track.yaml (giai đoạn chưa outline)');
  }
  for (final key in tree.trackOnlyModules) {
    final module = tree.modulesByKey[key]!;
    if (stageFilter != null && module.stage != stageFilter) continue;
    out.error(key, 'S03', 'module có trong track.yaml nhưng không có trong path.yaml');
  }
}

void checkS04Prereqs(ContentTree tree, IssueCollector out, {int? stageFilter}) {
  for (final lesson in tree.lessonsById.values) {
    if (stageFilter != null && lesson.stage != stageFilter) continue;
    for (final prereqId in lesson.prereqs) {
      final prereq = tree.lesson(prereqId);
      if (prereq == null) {
        out.error(lesson.id, 'S04', 'prereqs trỏ tới id không tồn tại: $prereqId');
        continue;
      }
      if (prereq.globalOrder >= 0 && lesson.globalOrder >= 0 && prereq.globalOrder >= lesson.globalOrder) {
        out.error(lesson.id, 'S04',
            'prereq $prereqId có thứ tự toàn cục (${prereq.globalOrder}) không nhỏ hơn bài hiện tại (${lesson.globalOrder})');
      }
    }
  }
}

void checkS05Skills(ContentTree tree, IssueCollector out, {int? stageFilter}) {
  for (final lesson in tree.lessonsById.values) {
    if (stageFilter != null && lesson.stage != stageFilter) continue;
    for (final skillId in lesson.skills) {
      if (!tree.skillExists(skillId)) {
        out.error(lesson.id, 'S05', 'skill không tồn tại trong bất kỳ track.yaml nào: $skillId');
      }
    }
  }
}

void checkS06Vocab(ContentTree tree, IssueCollector out, {int? stageFilter}) {
  for (final lesson in tree.lessonsInGlobalOrder) {
    if (stageFilter != null && lesson.stage != stageFilter) continue;
    for (final term in lesson.vocab) {
      final g = tree.glossaryTerm(term);
      if (g == null) {
        out.error(lesson.id, 'S06', 'vocab "$term" không có trong glossary.yaml');
        continue;
      }
      if (g.introducedIn != lesson.id) {
        out.error(lesson.id, 'S06',
            'glossary.introduced_in của "$term" là "${g.introducedIn}", không khớp bài này');
      }
    }
  }
  // term already declared by an earlier lesson
  final declaredBy = <String, String>{}; // term -> first lesson id that declares it
  for (final lesson in tree.lessonsInGlobalOrder) {
    for (final term in lesson.vocab) {
      if (declaredBy.containsKey(term)) {
        out.error(lesson.id, 'S06', 'vocab "$term" đã được bài "${declaredBy[term]}" khai báo trước đó');
      } else {
        declaredBy[term] = lesson.id;
      }
    }
  }
}

void checkS07ExampleFiles(
  ContentTree tree,
  Repo repo,
  IssueCollector out, {
  String? repoDir,
  bool noRepo = false,
  int? stageFilter,
}) {
  if (noRepo) return;
  final gitRepoPath = repo.path('examples/don-hang');
  for (final lesson in tree.lessonsById.values) {
    if (stageFilter != null && lesson.stage != stageFilter) continue;
    if (lesson.exampleFiles.isEmpty) continue;
    final tagExists = repoDir != null ? true : _gitTagExists(gitRepoPath, lesson.exampleTag);
    for (final file in lesson.exampleFiles) {
      final exists = repoDir != null
          ? File(p.join(repoDir, file)).existsSync()
          : _gitFileExists(gitRepoPath, lesson.exampleTag, file);
      if (!exists) {
        // A --repo-dir is always a not-yet-tagged draft seed (per SPEC, used at
        // the outline step): a file missing from it is "not built yet", the
        // same leniency as a git tag that doesn't exist yet — warn, don't block.
        if (!tagExists || repoDir != null) {
          out.warn(lesson.id, 'S07',
              'example_files "$file" chưa kiểm được: tag "${lesson.exampleTag}" chưa tồn tại (hoặc chưa có trong --repo-dir)');
        } else {
          out.error(lesson.id, 'S07', 'example_files "$file" không tồn tại ở tag "${lesson.exampleTag}"');
        }
      }
    }
  }
}

bool _gitTagExists(String gitRepoPath, String tag) {
  if (!Directory(p.join(gitRepoPath, '.git')).existsSync()) return false;
  final result = Process.runSync('git', ['-C', gitRepoPath, 'tag', '-l', tag]);
  return result.exitCode == 0 && (result.stdout as String).trim() == tag;
}

bool _gitFileExists(String gitRepoPath, String tag, String relPath) {
  if (!_gitTagExists(gitRepoPath, tag)) return false;
  final result = Process.runSync('git', ['-C', gitRepoPath, 'cat-file', '-e', '$tag:$relPath']);
  return result.exitCode == 0;
}

void checkS08Related(ContentTree tree, IssueCollector out, {int? stageFilter}) {
  for (final lesson in tree.lessonsById.values) {
    if (stageFilter != null && lesson.stage != stageFilter) continue;
    for (final relId in lesson.related) {
      final target = tree.lesson(relId);
      if (target == null) {
        out.warn(lesson.id, 'S08', 'related "$relId" chưa được outline (id hứa trước, cho phép)');
      }
    }
  }
}

/// Prints example_files for every lesson in [stage], for prompt 08's manifest.
List<String> manifestForStage(ContentTree tree, int stage) {
  final lines = <String>[];
  for (final lesson in tree.lessonsInGlobalOrder) {
    if (lesson.stage != stage) continue;
    for (final f in lesson.exampleFiles) {
      lines.add('$f\t${lesson.id}');
    }
  }
  return lines;
}
