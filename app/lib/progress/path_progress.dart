// Counting for S2 Lộ trình (docs/05 S2) and the prereq check of S5
// (docs/04 §2 `prereqs`). Pure: content + progress in, numbers out.
import 'package:flutter/foundation.dart';

import '../content/models/models.dart';
import 'lesson_status.dart';
import 'progress_repository.dart';

/// Gate pass mark (docs/07 §5.4: ≥ 75%).
const double gatePassRatio = 0.75;

/// `done/total`, where done = lessons `passed`.
@immutable
class PathCount {
  const PathCount(this.done, this.total);

  final int done;
  final int total;

  bool get complete => total > 0 && done == total;

  static PathCount of(
    Iterable<LessonRef> lessons,
    Map<String, LessonRecord> progress,
  ) {
    var done = 0;
    var total = 0;
    for (final r in lessons) {
      total++;
      if (progress[r.id]?.status == LessonStatus.passed) done++;
    }
    return PathCount(done, total);
  }
}

/// Modules of [stage] that exist in the track tree, in `path.yaml` order.
/// Keys without a `track.yaml` yet are left out (like stages that are not
/// outlined, docs/05 S2).
List<TrackModule> stageModules(Content content, PathStage stage) => [
  for (final key in stage.modules) ?content.module(key),
];

/// StageHeader "x/y": main-path lessons of the stage (docs/05 S2).
PathCount stageCount(
  Content content,
  PathStage stage,
  Map<String, LessonRecord> progress,
) => PathCount.of([
  for (final m in stageModules(content, stage))
    for (final r in m.lessons)
      if (r.mainPath) r,
], progress);

/// ModuleTile / track "x/y": every lesson, side branches included
/// (DECISIONS.md E7 counts every lesson of a module).
PathCount moduleCount(TrackModule module, Map<String, LessonRecord> progress) =>
    PathCount.of(module.lessons, progress);

/// "Quiz module" shows when every lesson of the module is at least `read`
/// (docs/05 S2).
bool moduleAllRead(TrackModule module, Map<String, LessonRecord> progress) =>
    module.lessons.isNotEmpty &&
    module.lessons.every(
      (r) => (progress[r.id]?.status ?? LessonStatus.newLesson).atLeast(
        LessonStatus.read,
      ),
    );

/// Gate line of StageHeader.
enum GateState { notTaken, failed, passed }

GateState gateState(StageRecord? r) {
  if (r == null) return GateState.notTaken;
  if (r.gatePassed) return GateState.passed;
  return r.attempts > 0 || r.bestGateScore != null
      ? GateState.failed
      : GateState.notTaken;
}

/// S5: prereqs of [lesson] that are not `passed`, in declared order. Only ids
/// present in `content.lessons` count — a "sắp có" lesson cannot be studied
/// first.
List<String> missingPrereqs(
  Content content,
  Lesson lesson,
  Map<String, LessonRecord> progress,
) => [
  for (final id in lesson.prereqs)
    if (id != lesson.id &&
        content.lessons.containsKey(id) &&
        progress[id]?.status != LessonStatus.passed)
      id,
];

/// Whether [lesson] has any prereq that can be opened (body in
/// `content.lessons`); without one S5 never applies.
bool hasOpenablePrereqs(Content content, Lesson lesson) => lesson.prereqs.any(
  (id) => id != lesson.id && content.lessons.containsKey(id),
);
