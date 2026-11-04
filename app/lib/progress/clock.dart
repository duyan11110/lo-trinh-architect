// Injectable time source — DECISIONS.md E7. Every progress write that stores
// a timestamp reads `Clock.now()` so tests can pin time.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Test clock: returns [time] until [advance] or [set] moves it.
class FixedClock implements Clock {
  FixedClock(this.time);

  DateTime time;

  @override
  DateTime now() => time;

  void advance(Duration d) => time = time.add(d);

  @visibleForTesting
  void set(DateTime t) => time = t;
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// ISO 8601 UTC, the only timestamp format in the database (docs/07 §4).
String isoUtc(DateTime t) => t.toUtc().toIso8601String();
