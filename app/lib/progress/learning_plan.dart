// "Học tiếp" and counting — docs/07 §5.2. Pure: content + progress in,
// plan out; no database, no clock.
import 'package:flutter/foundation.dart';

import '../content/models/models.dart';
import 'lesson_status.dart';
import 'progress_repository.dart';

/// Gate exam size shown on GateReadyCard (docs/07 §5.4: N = 35; docs/05 §7:
/// "~40 phút").
abstract final class GateSpec {
  static const int questions = 35;
  static const int minutes = 40;
}

/// One main-path lesson in path order.
@immutable
class MainPathEntry {
  const MainPathEntry({
    required this.ref,
    required this.module,
    required this.stage,
    required this.available,
  });

  final LessonRef ref;
  final TrackModule module;

  /// Stage whose `path.stages[].modules` lists [module].
  final int stage;

  /// The lesson body is in `content.lessons` (otherwise it is "sắp có").
  final bool available;

  String get id => ref.id;
}

/// "Bài x/y trong module": [index] is 1-based among **every** lesson of the
/// module, side branches included (DECISIONS.md E7).
@immutable
class LessonPosition {
  const LessonPosition({
    required this.module,
    required this.index,
    required this.total,
  });

  final TrackModule module;
  final int index;
  final int total;
}

LessonPosition? lessonPosition(Content content, String lessonId) {
  final lesson = content.lessons[lessonId];
  final modules = lesson != null
      ? [?content.module(lesson.moduleKey)]
      : [
          for (final t in content.tracks)
            for (final l in t.levels) ...l.modules,
        ];
  for (final m in modules) {
    final i = m.lessons.indexWhere((r) => r.id == lessonId);
    if (i >= 0) {
      return LessonPosition(module: m, index: i + 1, total: m.lessons.length);
    }
  }
  return null;
}

/// Main path = `path.stages[].modules` → track tree → lessons with
/// `main_path: true`, in that order.
List<MainPathEntry> buildMainPath(Content content) => [
  for (final s in content.stages)
    for (final key in s.modules)
      if (content.module(key) case final m?)
        for (final r in m.lessons)
          if (r.mainPath)
            MainPathEntry(
              ref: r,
              module: m,
              stage: s.stage,
              available: content.lessons.containsKey(r.id),
            ),
];

@immutable
class LearningPlan {
  const LearningPlan({
    required this.mainPath,
    required this.next,
    required this.currentStage,
    required this.remainingToGate,
    required this.gateReady,
    required this.pendingQuiz,
    required this.inProgress,
    required this.fresh,
  });

  /// docs/07 §5.2. Lessons not yet in `content.lessons` cannot be opened, so
  /// "Học tiếp" skips them; they still count towards the gate (they are not
  /// passed).
  factory LearningPlan.compute(
    Content content,
    Map<String, LessonRecord> progress,
    Set<int> passedGates,
  ) {
    final path = buildMainPath(content);
    LessonStatus status(String id) =>
        progress[id]?.status ?? LessonStatus.newLesson;

    final candidates = [
      for (final e in path)
        if (e.available && !status(e.id).atLeast(LessonStatus.read)) e,
    ];
    var next = candidates.isEmpty ? null : candidates.first;
    if (next != null) {
      MainPathEntry? recent;
      for (final e in candidates) {
        if (status(e.id) != LessonStatus.opened) continue;
        final t = progress[e.id]!.firstOpenedAt;
        final best = recent == null ? null : progress[recent.id]!.firstOpenedAt;
        if (recent == null || (t != null && (best == null || t.isAfter(best)))) {
          recent = e;
        }
      }
      if (recent != null && recent.module.key == next.module.key) next = recent;
    }

    int? currentStage;
    for (final s in content.stages) {
      if (!passedGates.contains(s.stage)) {
        currentStage = s.stage;
        break;
      }
    }
    final inStage = [
      for (final e in path)
        if (e.stage == currentStage) e,
    ];
    final remaining = inStage
        .where((e) => status(e.id) != LessonStatus.passed)
        .length;

    final pending =
        [
          for (final e in path)
            if (status(e.id) == LessonStatus.read) e,
        ]..sort(
          (a, b) => _desc(progress[a.id]!.readAt, progress[b.id]!.readAt),
        );

    final opened =
        [
          for (final p in progress.values)
            if (p.status == LessonStatus.opened &&
                p.lessonId != next?.id &&
                content.lessons.containsKey(p.lessonId))
              p,
        ]..sort((a, b) => _desc(a.firstOpenedAt, b.firstOpenedAt));

    return LearningPlan(
      mainPath: path,
      next: next,
      currentStage: currentStage,
      remainingToGate: remaining,
      gateReady: currentStage != null && inStage.isNotEmpty && remaining == 0,
      pendingQuiz: List.unmodifiable(pending.take(maxPendingQuiz)),
      inProgress: List.unmodifiable([for (final p in opened) p.lessonId]),
      fresh: progress.values.every((p) => p.status == LessonStatus.newLesson),
    );
  }

  /// "Quiz đang chờ": at most 5 rows (docs/07 §5.2).
  static const maxPendingQuiz = 5;

  static int _desc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  final List<MainPathEntry> mainPath;

  /// "Học tiếp": first main-path lesson that is `new`/`opened`, or the most
  /// recently opened one when it sits in the same module. `null` when none.
  final MainPathEntry? next;

  /// Smallest stage without `gate_passed_at`; `null` once every gate passed.
  final int? currentStage;

  /// "Còn N bài tới cổng": main-path lessons of [currentStage] not passed.
  final int remainingToGate;

  /// Every main-path lesson of [currentStage] passed, gate not yet passed.
  final bool gateReady;

  /// Main-path lessons in `read`, newest first.
  final List<MainPathEntry> pendingQuiz;

  /// "Đang dở": opened, not read, newest first, excluding [next].
  final List<String> inProgress;

  /// Nothing opened yet.
  final bool fresh;

  /// Every gate passed: the whole path is done.
  bool get finished => currentStage == null;
}
