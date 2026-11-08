// Migration + DDL test for the progress database (docs/07 §4, §11 M0).
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/progress/database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('schema versions', () {
    test('latest schemaVersion has a dumped schema', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(GeneratedHelper.versions.last, db.schemaVersion);
    });

    for (final from in GeneratedHelper.versions) {
      test('upgrade from v$from to latest matches the dumped schema', () async {
        final connection = await verifier.startAt(from);
        final db = AppDatabase(connection);
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, db.schemaVersion);
      });
    }

    test('fresh install (onCreate) matches the schema in code', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.validateDatabaseSchema();
    });
  });

  group('DDL per docs/07 §4', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('creates exactly the tables in §4', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_schema WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'search_index_%'",
          )
          .get();
      expect(rows.map((r) => r.read<String>('name')).toSet(), {
        'lesson_progress',
        'quiz_attempt',
        'quiz_answer',
        'review_item',
        'vocab_seen',
        'stage_progress',
        'settings',
        'event',
        'search_index',
      });
    });

    test('CHECK constraints reject unknown enum values', () async {
      await db.customStatement(
        "INSERT INTO lesson_progress (lesson_id, status) VALUES ('a', 'new')",
      );
      expect(
        () => db.customStatement(
          "INSERT INTO lesson_progress (lesson_id, status) VALUES ('b', 'done')",
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => db.customStatement(
          "INSERT INTO quiz_attempt (kind, ref_id, started_at, question_ids) "
          "VALUES ('exam', 'x', '2026-01-01T00:00:00Z', '[]')",
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => db.customStatement(
          "INSERT INTO review_item (item_id, kind, due_at) "
          "VALUES ('q1', 'card', '2026-01-01T00:00:00Z')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('defaults are applied', () async {
      await db.customStatement(
        "INSERT INTO lesson_progress (lesson_id, status) VALUES ('a', 'new')",
      );
      final row = await db
          .customSelect(
            'SELECT scroll_ratio, prereq_warned FROM lesson_progress',
          )
          .getSingle();
      expect(row.read<double>('scroll_ratio'), 0);
      expect(row.read<int>('prereq_warned'), 0);
    });

    test('deleting an attempt cascades to its answers', () async {
      await db.customStatement(
        "INSERT INTO quiz_attempt (kind, ref_id, started_at, question_ids) "
        "VALUES ('lesson', 'l1', '2026-01-01T00:00:00Z', '[\"q1\"]')",
      );
      await db.customStatement(
        "INSERT INTO quiz_answer (attempt_id, question_id, answer, correct, "
        "answered_at) VALUES (1, 'q1', '[\"b\"]', 1, '2026-01-01T00:01:00Z')",
      );
      await db.customStatement('DELETE FROM quiz_attempt WHERE id = 1');
      final n = await db
          .customSelect('SELECT COUNT(*) AS n FROM quiz_answer')
          .getSingle();
      expect(n.read<int>('n'), 0);
    });

    test('search_index is FTS5 and keeps Vietnamese diacritics', () async {
      await db.customStatement(
        'INSERT INTO search_index (lesson_id, lang, title, body) '
        "VALUES ('l1', 'vi', 'Bài một', 'học về request')",
      );
      Future<int> count(String q) async => (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM search_index '
                'WHERE search_index MATCH ?',
                variables: [Variable.withString(q)],
              )
              .getSingle())
          .read<int>('n');
      expect(await count('học'), 1);
      expect(await count('hoc'), 0);
    });
  });
}
