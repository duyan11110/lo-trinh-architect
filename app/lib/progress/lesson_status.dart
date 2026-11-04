// `lesson_progress.status` (docs/07 §4, §5.1). Ordered: a lesson never moves
// to a lower status.
enum LessonStatus {
  newLesson('new'),
  opened('opened'),
  read('read'),
  passed('passed');

  const LessonStatus(this.db);

  /// Value stored in the database (`newLesson` is stored as `new`).
  final String db;

  static LessonStatus fromDb(String? s) =>
      values.firstWhere((v) => v.db == s, orElse: () => newLesson);

  bool atLeast(LessonStatus other) => index >= other.index;

  /// `max(this, other)` — the only way statuses change (never downgrade).
  LessonStatus raiseTo(LessonStatus other) => other.index > index ? other : this;
}
