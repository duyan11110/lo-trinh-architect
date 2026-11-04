// Gate data for S8, the exam, its result and the failed-gate card on S1
// (docs/05 S1, S6, S8; docs/07 §5.4).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../progress/exam_repository.dart';
import '../../progress/gate_sampler.dart';
import '../../progress/quiz_repository.dart';

/// `path.stages[]` entry and its gate bank, when content.json has one.
(PathStage, Gate)? stageGate(Content content, int stage) {
  final s = content.stages.where((s) => s.stage == stage).firstOrNull;
  if (s == null) return null;
  final g = content.gates[s.gate];
  if (g == null || g.questions.isEmpty) return null;
  return (s, g);
}

/// Score of a finished gate attempt broken down by track, and the lessons
/// worth rereading.
@immutable
class GateOutcome {
  const GateOutcome({
    required this.attempt,
    required this.score,
    required this.total,
    required this.byTrack,
    required this.reread,
  });

  final QuizAttemptRecord attempt;
  final int score;
  final int total;

  /// Track id (`null` = cross-track) → (correct, asked), in first-seen order.
  final Map<String?, (int, int)> byTrack;

  /// Lesson ids (docs/07 §5.4 "Nên đọc lại").
  final List<String> reread;

  double get ratio => total == 0 ? 0 : score / total;
}

GateOutcome gateOutcome(Content content, Gate gate, QuizAttemptRecord a) {
  final bank = {for (final q in gate.questions) q.id: q};
  final byTrack = <String?, (int, int)>{};
  final wrong = <Question>[];
  var score = 0;
  for (final id in a.questionIds) {
    final q = bank[id];
    final correct = a.answers[id]?.correct ?? false;
    if (correct) score++;
    if (q == null) continue;
    if (!correct) wrong.add(q);
    final t = gateTrackOf(q);
    final (c, n) = byTrack[t] ?? (0, 0);
    byTrack[t] = (c + (correct ? 1 : 0), n + 1);
  }
  return GateOutcome(
    attempt: a,
    score: a.score ?? score,
    total: a.total ?? a.questionIds.length,
    byTrack: byTrack,
    reread: GateSampler.rereadLessons(content, wrong),
  );
}

/// Latest finished attempt of [stage]'s gate, analysed (S1 failed card).
final lastGateOutcomeProvider = FutureProvider.autoDispose
    .family<GateOutcome?, int>((ref, stage) async {
      final content = await ref.watch(contentProvider.future);
      final sg = stageGate(content, stage);
      if (sg == null) return null;
      final history = await ref.watch(gateHistoryProvider(sg.$2.gate).future);
      if (history.isEmpty) return null;
      final a = await ref
          .watch(quizRepositoryProvider)
          .attempt(history.first.attemptId);
      return a == null ? null : gateOutcome(content, sg.$2, a);
    });

/// The paused exam of [stage] inside its 24-hour window (S8 "Tiếp tục").
final pausedGateProvider = FutureProvider.autoDispose
    .family<QuizAttemptRecord?, int>((ref, stage) async {
      final content = await ref.watch(contentProvider.future);
      final sg = stageGate(content, stage);
      if (sg == null) return null;
      ref.watch(gateHistoryProvider(sg.$2.gate));
      return ref.watch(examRepositoryProvider).pausedGate(sg.$2);
    });
