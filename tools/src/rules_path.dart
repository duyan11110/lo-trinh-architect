/// T01–T03 — content/path.yaml structural rules (only run with --structure-only).
library rules_path;

import 'content_tree.dart';
import 'errors.dart';
import 'schema_validator.dart';

void validatePath(ContentTree tree, SchemaValidator sv, IssueCollector out) {
  final schemaErrs = sv.validate('path.schema.json', tree.pathYaml);
  for (final e in schemaErrs) {
    out.error('path.yaml', 'T01', 'không qua schema: $e');
  }

  final stages = (tree.pathYaml['stages'] as List? ?? []);
  if (stages.length != 5) {
    out.error('path.yaml', 'T01', 'phải có đúng 5 stage, thấy ${stages.length}');
  }
  final stageNums = stages.map((s) => (s as Map)['stage'] as int).toList();
  if (stageNums.toSet().length != stageNums.length) {
    out.error('path.yaml', 'T01', 'stage bị lặp: $stageNums');
  }

  final moduleStageOf = <String, List<int>>{};
  for (final s in stages) {
    final stage = (s as Map)['stage'] as int;
    for (final m in (s['modules'] as List? ?? [])) {
      moduleStageOf.putIfAbsent(m.toString(), () => []).add(stage);
    }
  }
  for (final e in moduleStageOf.entries) {
    if (e.value.length > 1) {
      out.error('path.yaml', 'T01', 'module "${e.key}" lặp lại ở nhiều stage: ${e.value}');
    }
    if (!tree.modulesByKey.containsKey(e.key)) {
      // covered as a warning by S03 (module chưa outline); T01 only flags true
      // structural garbage, so nothing further here.
    }
  }

  // T02: a main_path lesson must not have a branch (main_path:false) lesson as a prereq
  for (final lesson in tree.lessonsById.values) {
    if (!lesson.mainPath) continue;
    for (final prereqId in lesson.prereqs) {
      final prereq = tree.lesson(prereqId);
      if (prereq != null && !prereq.mainPath) {
        out.error(lesson.id, 'T02', 'bài main_path có prereq "$prereqId" là nhánh phụ (main_path:false)');
      }
    }
  }

  // T03: module stage in track.yaml must match its stage in path.yaml
  for (final key in tree.modulesByKey.keys) {
    final module = tree.modulesByKey[key]!;
    final pathStage = tree.moduleStageInPath[key];
    if (pathStage != null && pathStage != module.stage) {
      out.error(key, 'T03',
          'stage trong track.yaml (${module.stage}) khác stage trong path.yaml ($pathStage)');
    }
  }
}
