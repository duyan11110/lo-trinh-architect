// Migration strategy — docs/07 §4. Each schemaVersion bump adds one step to
// [_steps] and bumps
// `AppDatabase.schemaVersion`; never drop a table holding user data (app/CLAUDE.md rule 7).
import 'package:drift/drift.dart';

typedef _Step = Future<void> Function(Migrator m);

/// `_steps[n]` upgrades a database from version `n` to `n + 1`.
final Map<int, _Step> _steps = {};

MigrationStrategy buildMigrationStrategy(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      for (var v = from; v < to; v++) {
        final step = _steps[v];
        if (step == null) {
          throw StateError('No migration step from schema $v to ${v + 1}');
        }
        await step(m);
      }
    },
    beforeOpen: (details) async {
      // quiz_answer → quiz_attempt uses ON DELETE CASCADE.
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
