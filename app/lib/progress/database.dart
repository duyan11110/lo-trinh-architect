// Drift database — schema in tables.drift (docs/07 §4), migrations in
// migrations.dart.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'migrations.dart';

part 'database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  // Literal (read by `drift_dev make-migrations`). Bump together with a new
  // step in migrations.dart.
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);

  static QueryExecutor _open() => driftDatabase(
        name: 'lta_progress',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
}
