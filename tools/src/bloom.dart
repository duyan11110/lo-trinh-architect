/// A.4 — Bloom distribution rounding, and docs/01 §6 table.
library bloom;

import 'dart:math' as math;

/// stage -> {bloom-bucket: percentage}. "analyze" and "evaluate" are pooled.
const Map<int, Map<String, double>> kBloomDistribution = {
  0: {'remember': 25, 'understand': 45, 'apply': 25, 'analyze_evaluate': 5},
  1: {'remember': 15, 'understand': 40, 'apply': 35, 'analyze_evaluate': 10},
  2: {'remember': 10, 'understand': 30, 'apply': 40, 'analyze_evaluate': 20},
  3: {'remember': 5, 'understand': 20, 'apply': 40, 'analyze_evaluate': 35},
  4: {'remember': 0, 'understand': 10, 'apply': 30, 'analyze_evaluate': 60},
};

String bloomBucket(String bloom) =>
    (bloom == 'analyze' || bloom == 'evaluate') ? 'analyze_evaluate' : bloom;

/// For [n] questions and expected proportion [p] (0-100), the accepted
/// count range is [floor(e)-1, ceil(e)+1] ∩ [0, n], e = n * p / 100.
class Range {
  final int min;
  final int max;
  Range(this.min, this.max);
  bool contains(int v) => v >= min && v <= max;
}

Range acceptedCountRange(int n, double percent) {
  final e = n * percent / 100.0;
  final lo = math.max(0, e.floor() - 1);
  final hi = math.min(n, e.ceil() + 1);
  return Range(lo, hi);
}
