// Progress export / import / reset — docs/07 §4: JSON `{schema: 1,
// exported_at, tables: {...}}` without `event` and `search_index`; import =
// clear those tables and insert, in one transaction. Column names come from
// the database schema, never from the file.
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'database.dart';
import 'progress_repository.dart';

/// Format version of the export file.
const int progressExportSchema = 1;

/// Exported tables, in insert order (quiz_answer after quiz_attempt).
const List<String> progressTables = [
  'lesson_progress',
  'quiz_attempt',
  'quiz_answer',
  'review_item',
  'vocab_seen',
  'stage_progress',
  'settings',
];

/// The file is not a valid progress export; nothing was changed.
class ProgressImportException implements Exception {
  const ProgressImportException(this.message);
  final String message;

  @override
  String toString() => 'ProgressImportException: $message';
}

class ProgressTransfer {
  ProgressTransfer(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Settings that describe this device's content cache, not progress: not
  /// carried over by an import (the stored content may not exist there).
  static const deviceSettings = {
    'content_version',
    'content_source',
    'search_index_version',
  };

  TableInfo<Table, dynamic> _table(String name) =>
      _db.allTables.firstWhere((t) => t.actualTableName == name);

  Future<String> exportJson() async {
    final tables = <String, Object>{};
    for (final name in progressTables) {
      final rows = await _db.customSelect('SELECT * FROM "$name"').get();
      tables[name] = [for (final r in rows) r.data];
    }
    return const JsonEncoder.withIndent(' ').convert({
      'schema': progressExportSchema,
      'exported_at': isoUtc(_clock.now()),
      'tables': tables,
    });
  }

  /// Suggested file name: `lta-progress-yyyy-MM-dd.json`.
  String fileName() {
    final d = _clock.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'lta-progress-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Replaces every exported table with the file's rows. Throws
  /// [ProgressImportException] (database untouched) on a malformed file.
  Future<void> importJson(String source) async {
    final rows = _parse(source);
    await _db.transaction(() async {
      final keepDevice = await _db
          .customSelect(
            'SELECT "key", value FROM settings WHERE "key" IN '
            '(${List.filled(deviceSettings.length, '?').join(', ')})',
            variables: [for (final k in deviceSettings) Variable.withString(k)],
          )
          .get();
      await _clear();
      for (final name in progressTables) {
        for (final row in rows[name]!) {
          if (name == 'settings' && deviceSettings.contains(row['key'])) {
            continue;
          }
          final cols = row.keys.toList();
          await _db.customInsert(
            'INSERT INTO "$name" (${cols.map((c) => '"$c"').join(', ')}) '
            'VALUES (${List.filled(cols.length, '?').join(', ')})',
            variables: [for (final c in cols) _variable(row[c])],
          );
        }
      }
      for (final r in keepDevice) {
        await _db.customInsert(
          'INSERT OR REPLACE INTO settings ("key", value) VALUES (?, ?)',
          variables: [
            Variable.withString(r.read<String>('key')),
            Variable.withString(r.read<String>('value')),
          ],
        );
      }
    });
    _db.notifyUpdates({
      for (final name in progressTables) TableUpdate(name),
    });
  }

  /// "Đặt lại": clears every exported table except this device's content
  /// settings.
  Future<void> reset() async {
    await _db.transaction(() async {
      await _clear(keepDeviceSettings: true);
    });
    _db.notifyUpdates({
      for (final name in progressTables) TableUpdate(name),
    });
  }

  Future<void> _clear({bool keepDeviceSettings = false}) async {
    for (final name in progressTables.reversed) {
      if (name == 'settings' && keepDeviceSettings) {
        await _db.customStatement(
          'DELETE FROM settings WHERE "key" NOT IN '
          '(${List.filled(deviceSettings.length, '?').join(', ')})',
          deviceSettings.toList(),
        );
      } else {
        await _db.customStatement('DELETE FROM "$name"');
      }
    }
  }

  Map<String, List<Map<String, Object?>>> _parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw ProgressImportException('not JSON: ${e.message}');
    }
    if (json is! Map<String, Object?> || json['schema'] != progressExportSchema) {
      throw const ProgressImportException('unknown schema');
    }
    final tables = json['tables'];
    if (tables is! Map<String, Object?>) {
      throw const ProgressImportException('no tables');
    }
    final out = <String, List<Map<String, Object?>>>{};
    for (final name in progressTables) {
      final rows = tables[name] ?? const <Object?>[];
      if (rows is! List) throw ProgressImportException('$name is not a list');
      final columns = {for (final c in _table(name).$columns) c.name};
      out[name] = [
        for (final r in rows)
          if (r is Map<String, Object?> &&
              r.isNotEmpty &&
              r.keys.every(columns.contains) &&
              r.values.every((v) => v == null || v is num || v is String))
            r
          else
            throw ProgressImportException('bad row in $name'),
      ];
    }
    return out;
  }

  static Variable<Object> _variable(Object? v) => switch (v) {
    null => const Variable(null),
    final int i => Variable.withInt(i),
    final double d => Variable.withReal(d),
    final String s => Variable.withString(s),
    _ => throw ProgressImportException('bad value $v'),
  };
}

final progressTransferProvider = Provider<ProgressTransfer>(
  (ref) => ProgressTransfer(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);
