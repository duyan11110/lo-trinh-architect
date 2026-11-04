// Storage of downloaded content versions — docs/07 §7 "ghi
// `content.<version>.json` trong thư mục app". Kept in a second, content-only
// SQLite file (`lta_content`) opened like the progress database, so the same
// code works on Android and on web (WASM + OPFS) without a file-system
// package (DECISIONS.md §3, M6). The progress database never holds content.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Downloaded `content.json` texts by `content_version`.
abstract interface class ContentStore {
  Future<String?> read(int version);

  /// Stores [json] as [version]; atomic (all or nothing).
  Future<void> write(int version, String json);

  /// Deletes every stored version except [keep] (`null` = delete all).
  Future<void> deleteExcept(int? keep);
}

/// The content cache database: one table, no generated code.
class ContentCacheDatabase extends GeneratedDatabase {
  ContentCacheDatabase([QueryExecutor? executor])
    : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(
    name: 'lta_content',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => customStatement(
      'CREATE TABLE IF NOT EXISTS content_file '
      '(version INTEGER PRIMARY KEY, json TEXT NOT NULL)',
    ),
  );
}

class SqliteContentStore implements ContentStore {
  SqliteContentStore(this._db);

  final ContentCacheDatabase _db;

  @override
  Future<String?> read(int version) async {
    final row = await _db
        .customSelect(
          'SELECT json FROM content_file WHERE version = ?',
          variables: [Variable.withInt(version)],
        )
        .getSingleOrNull();
    return row?.read<String>('json');
  }

  @override
  Future<void> write(int version, String json) => _db.transaction(
    () => _db.customStatement(
      'INSERT OR REPLACE INTO content_file (version, json) VALUES (?, ?)',
      [version, json],
    ),
  );

  @override
  Future<void> deleteExcept(int? keep) => keep == null
      ? _db.customStatement('DELETE FROM content_file')
      : _db.customStatement('DELETE FROM content_file WHERE version <> ?', [
          keep,
        ]);

  Future<void> close() => _db.close();
}

/// In-memory store (tests; never persisted).
class MemoryContentStore implements ContentStore {
  final files = <int, String>{};

  @override
  Future<String?> read(int version) async => files[version];

  @override
  Future<void> write(int version, String json) async => files[version] = json;

  @override
  Future<void> deleteExcept(int? keep) async =>
      files.removeWhere((v, _) => v != keep);
}
