// Gate exam draw and result analysis — docs/07 §5.4. Pure: content, the bank
// and the previous draw in, question ids out. Randomness is injected
// (DECISIONS.md E7); the caller seeds it with the attempt id.
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/models/models.dart';
import 'learning_plan.dart';

/// Track of a gate question; `null` for cross-track questions (`track`
/// missing or empty in content.json).
String? gateTrackOf(Question q) =>
    (q.track == null || q.track!.isEmpty) ? null : q.track;

abstract final class GateSampler {
  /// Questions per exam (docs/07 §5.4: N = 35).
  static const int size = GateSpec.questions;

  /// Cross-track `scenario` questions per exam.
  static const int crossScenarios = 3;

  /// Draws [size] question ids from [gate] for its stage of [content].
  ///
  /// 1. Ids of the last attempt ([lastUsed]) are excluded when the bank still
  ///    has ≥ N others, otherwise only drawn after every unused one.
  /// 2. Up to 3 cross-track `scenario` questions.
  /// 3. Per track `k_t = round((N − cross) × lessons_t / Σ lessons)` over the
  ///    tracks' main-path lessons in the stage, adjusted ±1 to the total and
  ///    capped by what the track has; round-robin over modules.
  /// 4. The whole draw is shuffled.
  static List<String> sample({
    required Content content,
    required Gate gate,
    required Random random,
    Iterable<String> lastUsed = const [],
    int n = size,
  }) {
    final used = lastUsed.toSet();
    final bank = [...gate.questions]..sort((a, b) => a.id.compareTo(b.id));
    final unusedCount = bank.where((q) => !used.contains(q.id)).length;
    final pool = unusedCount >= n
        ? [for (final q in bank) if (!used.contains(q.id)) q]
        : bank;
    if (pool.length <= n) {
      return [for (final q in pool) q.id]..shuffle(random);
    }

    /// Unused first, each part shuffled.
    List<Question> ordered(Iterable<Question> qs) {
      final fresh = [for (final q in qs) if (!used.contains(q.id)) q]
        ..shuffle(random);
      final again = [for (final q in qs) if (used.contains(q.id)) q]
        ..shuffle(random);
      return [...fresh, ...again];
    }

    final picked = <Question>[];
    final cross = ordered([
      for (final q in pool)
        if (gateTrackOf(q) == null && q.type == QuestionType.scenario) q,
    ]);
    picked.addAll(cross.take(min(crossScenarios, n)));

    final byTrack = <String, List<Question>>{};
    for (final q in pool) {
      final t = gateTrackOf(q);
      if (t != null) (byTrack[t] ??= []).add(q);
    }
    final weights = trackWeights(content, gate.stage);
    final tracks = byTrack.keys.toList()..sort();
    final quotas = allocate(
      n - picked.length,
      {for (final t in tracks) t: weights[t] ?? 0},
      {for (final t in tracks) t: byTrack[t]!.length},
    );
    for (final t in tracks) {
      picked.addAll(_roundRobin(byTrack[t]!, quotas[t]!, ordered, random));
    }

    // Short (a track without lessons, too few questions): fill from the rest.
    if (picked.length < n) {
      final ids = {for (final q in picked) q.id};
      picked.addAll(
        ordered([for (final q in pool) if (!ids.contains(q.id)) q])
            .take(n - picked.length),
      );
    }
    return [for (final q in picked) q.id]..shuffle(random);
  }

  /// Main-path lessons per track in [stage] (the §5.4 ratio).
  static Map<String, int> trackWeights(Content content, int stage) {
    final out = <String, int>{};
    for (final e in buildMainPath(content)) {
      if (e.stage == stage) out[e.module.track] = (out[e.module.track] ?? 0) + 1;
    }
    return out;
  }

  /// Largest-remainder rounding of [total] over [weights], each capped by
  /// [caps]; overflow goes to tracks with room, by weight.
  @visibleForTesting
  static Map<String, int> allocate(
    int total,
    Map<String, int> weights,
    Map<String, int> caps,
  ) {
    final keys = weights.keys.toList()..sort();
    final out = {for (final k in keys) k: 0};
    var remaining = total;
    var active = [for (final k in keys) if (weights[k]! > 0 && caps[k]! > 0) k];
    while (remaining > 0 && active.isNotEmpty) {
      final sum = active.fold<int>(0, (s, k) => s + weights[k]!);
      final exact = {for (final k in active) k: remaining * weights[k]! / sum};
      final share = {for (final k in active) k: exact[k]!.round()};
      var diff = remaining - share.values.fold<int>(0, (s, v) => s + v);
      // ±1 by the fractional part so the shares add up to `remaining`.
      final byFraction = [...active]
        ..sort((a, b) {
          final fa = exact[a]! - exact[a]!.floor();
          final fb = exact[b]! - exact[b]!.floor();
          final c = diff > 0 ? fb.compareTo(fa) : fa.compareTo(fb);
          return c != 0 ? c : a.compareTo(b);
        });
      for (var i = 0; diff != 0 && i < byFraction.length * 2; i++) {
        final k = byFraction[i % byFraction.length];
        if (diff > 0) {
          share[k] = share[k]! + 1;
          diff--;
        } else if (share[k]! > 0) {
          share[k] = share[k]! - 1;
          diff++;
        }
      }
      var given = 0;
      for (final k in active) {
        final room = caps[k]! - out[k]!;
        final g = min(share[k]!, room);
        out[k] = out[k]! + g;
        given += g;
      }
      remaining -= given;
      active = [for (final k in active) if (caps[k]! > out[k]!) k];
      if (given == 0) break;
    }
    // Tracks without lessons in the stage only fill what is still missing.
    for (final k in keys) {
      if (remaining <= 0) break;
      final g = min(remaining, caps[k]! - out[k]!);
      out[k] = out[k]! + g;
      remaining -= g;
    }
    return out;
  }

  static List<Question> _roundRobin(
    List<Question> qs,
    int k,
    List<Question> Function(Iterable<Question>) ordered,
    Random random,
  ) {
    final byModule = <String, List<Question>>{};
    for (final q in qs) {
      (byModule[q.module ?? ''] ??= []).add(q);
    }
    final modules = byModule.keys.toList()
      ..sort()
      ..shuffle(random);
    final queues = {for (final m in modules) m: ordered(byModule[m]!)};
    final out = <Question>[];
    while (out.length < k) {
      var progressed = false;
      for (final m in modules) {
        if (out.length >= k) break;
        final queue = queues[m]!;
        if (queue.isEmpty) continue;
        out.add(queue.removeAt(0));
        progressed = true;
      }
      if (!progressed) break;
    }
    return out;
  }

  /// "Nên đọc lại" (docs/07 §5.4): for each wrong question its `skills` →
  /// `skills[].lessons`; lessons hit by ≥ 2 wrong questions, or the top 3
  /// when none is. Order: most hits first, then path order.
  static List<String> rereadLessons(Content content, Iterable<Question> wrong) {
    final skills = {for (final s in content.skills) s.id: s};
    final hits = <String, int>{};
    for (final q in wrong) {
      final lessons = {
        for (final id in q.skills) ...?skills[id]?.lessons,
      };
      for (final l in lessons) {
        hits[l] = (hits[l] ?? 0) + 1;
      }
    }
    final order = {
      for (final (i, e) in buildMainPath(content).indexed) e.id: i,
    };
    final ranked = hits.keys.toList()
      ..sort((a, b) {
        final c = hits[b]!.compareTo(hits[a]!);
        if (c != 0) return c;
        final oa = order[a] ?? 1 << 30;
        final ob = order[b] ?? 1 << 30;
        return oa != ob ? oa.compareTo(ob) : a.compareTo(b);
      });
    final twice = [for (final l in ranked) if (hits[l]! >= 2) l];
    return twice.isNotEmpty ? twice : ranked.take(3).toList();
  }
}
