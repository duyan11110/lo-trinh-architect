// `settings` key/value table — docs/07 §4. S10 Cài đặt reads and writes it;
// the reading prefs, content language and theme follow it live.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'progress_repository.dart';

/// Keys of `settings` (docs/07 §4). The last three are M6 additions
/// (DECISIONS.md §3).
abstract final class SettingKeys {
  static const contentLang = 'content_lang';
  static const theme = 'theme';
  static const fontScale = 'font_scale';
  static const lineHeight = 'line_height';
  static const reviewMax = 'review_max_per_session';
  static const contentVersion = 'content_version';
  static const contentSource = 'content_source';
  static const remoteBaseUrl = 'remote_base_url';

  /// Last background manifest check (ISO 8601 UTC), for the 24-hour rule.
  static const contentCheckedAt = 'content_checked_at';
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async => (await (_db.select(
    _db.settings,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> set(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: Value(key), value: value),
      );

  Future<void> remove(String key) =>
      (_db.delete(_db.settings)..where((t) => t.key.equals(key))).go();

  Stream<Map<String, String>> watchAll() => _db
      .select(_db.settings)
      .watch()
      .map((rows) => {for (final r in rows) r.key!: r.value});
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Every setting, live.
final settingsProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchAll(),
);
