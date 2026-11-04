// Loading content.json — docs/07 §7–§8: the bundled asset, or a downloaded
// version (manifest → sha256 → gunzip → parse → store → switch settings in
// one transaction). Any failure keeps the content in use untouched.
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../progress/clock.dart';
import '../progress/database.dart';
import '../progress/settings_repository.dart';
import 'content_store.dart';
import 'models/models.dart';

/// docs/07 §7 / DECISIONS.md A5: default `remote_base_url`. A `settings`
/// row of the same key overrides it.
const String defaultRemoteBaseUrl =
    'https://duyan11110.github.io/lo-trinh-architect/content/';

/// `settings.content_source`.
enum ContentSourceKind { asset, remote }

/// Where content.json comes from (`settings.content_source`).
abstract interface class ContentSource {
  Future<String> read();
}

/// `assets/content/content.json`, copied from `dist/` by
/// `tools/sync-app-content` (DECISIONS.md E6: the sample until M7).
class AssetContentSource implements ContentSource {
  AssetContentSource({this._bundle, this.path = defaultPath});

  static const defaultPath = 'assets/content/content.json';

  final AssetBundle? _bundle;
  final String path;

  @override
  Future<String> read() => (_bundle ?? rootBundle).loadString(path, cache: false);
}

/// The source the settings point at: the stored remote version when
/// `content_source = remote` and that version is stored, else the asset.
class ResolvedContentSource implements ContentSource {
  ResolvedContentSource({
    required this.asset,
    required this.store,
    required this.settings,
  });

  final ContentSource asset;
  final ContentStore store;
  final SettingsRepository settings;

  @override
  Future<String> read() async {
    try {
      final kind = await settings.get(SettingKeys.contentSource);
      final version = int.tryParse(
        await settings.get(SettingKeys.contentVersion) ?? '',
      );
      if (kind == ContentSourceKind.remote.name && version != null) {
        final json = await store.read(version);
        if (json != null) return json;
        debugPrint('content v$version not stored; using the bundled asset');
      }
    } catch (e) {
      debugPrint('stored content unavailable ($e); using the bundled asset');
    }
    return asset.read();
  }
}

/// Parses [ContentSource] output into an immutable [Content].
class ContentLoader {
  const ContentLoader({this.background = true});

  /// Parse on a background isolate (`compute`, which falls back to the main
  /// isolate on web). Tests running in fake-async zones pass `false`.
  final bool background;

  Future<Content> load(ContentSource source) async => parse(await source.read());

  Future<Content> parse(String raw) async =>
      background ? compute(parseContent, raw) : parseContent(raw);
}

/// `manifest.json` (docs/07 §7).
@immutable
class ContentManifest {
  const ContentManifest({
    required this.contentVersion,
    required this.builtAt,
    required this.sha256,
    this.bytes,
    this.lessonsAdded = const [],
    this.lessonsChanged = const [],
  });

  factory ContentManifest.fromJson(Object? json) {
    final m = asMap(json, 'manifest');
    return ContentManifest(
      contentVersion: m.integer('content_version'),
      builtAt: m.str('built_at'),
      sha256: m.str('sha256').toLowerCase(),
      bytes: m.intOrNull('bytes'),
      lessonsAdded: m.stringsOrEmpty('lessons_added'),
      lessonsChanged: m.stringsOrEmpty('lessons_changed'),
    );
  }

  final int contentVersion;
  final String builtAt;

  /// Hex sha256 of `content.json.gz`.
  final String sha256;
  final int? bytes;
  final List<String> lessonsAdded;
  final List<String> lessonsChanged;
}

/// Which step of an update failed. The content in use is untouched in every
/// case (docs/07 §7, docs/05 §10).
enum ContentUpdateFailure { network, checksum, corrupt, storage }

class ContentUpdateException implements Exception {
  const ContentUpdateException(this.failure, [this.cause]);

  final ContentUpdateFailure failure;
  final Object? cause;

  @override
  String toString() => 'ContentUpdateException(${failure.name}: $cause)';
}

/// HTTP access to `remote_base_url` (docs/07 §7). The client is injected so
/// tests never touch the network.
class RemoteContent {
  RemoteContent(this._client, String baseUrl)
    : baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');

  static const manifestFile = 'manifest.json';
  static const archiveFile = 'content.json.gz';

  final http.Client _client;
  final Uri baseUri;

  Future<Uint8List> _get(String file) async {
    final http.Response res;
    try {
      res = await _client.get(baseUri.resolve(file));
    } catch (e) {
      throw ContentUpdateException(ContentUpdateFailure.network, e);
    }
    if (res.statusCode != 200) {
      throw ContentUpdateException(
        ContentUpdateFailure.network,
        'HTTP ${res.statusCode} for $file',
      );
    }
    return res.bodyBytes;
  }

  Future<ContentManifest> manifest() async {
    final bytes = await _get(manifestFile);
    try {
      return ContentManifest.fromJson(jsonDecode(utf8.decode(bytes)));
    } catch (e) {
      throw ContentUpdateException(ContentUpdateFailure.corrupt, e);
    }
  }

  Future<Uint8List> archive() => _get(archiveFile);
}

/// The update steps of docs/07 §7, in order: download → sha256 → gunzip →
/// parse → store → switch `settings` in one transaction → drop older
/// stored versions. Nothing the app reads changes before the switch.
class ContentUpdater {
  ContentUpdater({
    required this.remote,
    required this.store,
    required this.db,
    required this.clock,
    this.loader = const ContentLoader(),
  });

  final RemoteContent remote;
  final ContentStore store;
  final AppDatabase db;
  final Clock clock;
  final ContentLoader loader;

  /// Applies [manifest]'s version; returns the parsed new content. Throws
  /// [ContentUpdateException], leaving settings and the store as they were.
  Future<Content> apply(ContentManifest manifest) async {
    final gz = await remote.archive();
    if (sha256.convert(gz).toString() != manifest.sha256) {
      throw const ContentUpdateException(ContentUpdateFailure.checksum);
    }
    final String json;
    final Content content;
    try {
      json = utf8.decode(const GZipDecoder().decodeBytes(gz, throwOnError: true));
      content = await loader.parse(json);
    } catch (e) {
      throw ContentUpdateException(ContentUpdateFailure.corrupt, e);
    }
    final version = content.meta.contentVersion;
    if (version != manifest.contentVersion) {
      throw ContentUpdateException(
        ContentUpdateFailure.corrupt,
        'manifest v${manifest.contentVersion}, content v$version',
      );
    }
    final previous = await SettingsRepository(db).get(SettingKeys.contentVersion);
    try {
      await store.write(version, json);
    } catch (e) {
      throw ContentUpdateException(ContentUpdateFailure.storage, e);
    }
    try {
      await db.transaction(() async {
        final s = SettingsRepository(db);
        await s.set(SettingKeys.contentVersion, '$version');
        await s.set(SettingKeys.contentSource, ContentSourceKind.remote.name);
        await db
            .into(db.event)
            .insert(
              EventCompanion.insert(
                ts: isoUtc(clock.now()),
                kind: 'content_updated',
                value: Value(version.toDouble()),
              ),
            );
      });
    } catch (e) {
      // Settings still point at the old version; drop only the new file.
      await _quietly(() => store.deleteExcept(int.tryParse(previous ?? '')));
      throw ContentUpdateException(ContentUpdateFailure.storage, e);
    }
    await _quietly(() => store.deleteExcept(version));
    return content;
  }

  /// "Dùng bản đóng gói": `content_source = asset`; stored versions go.
  Future<void> useBundled() async {
    await SettingsRepository(
      db,
    ).set(SettingKeys.contentSource, ContentSourceKind.asset.name);
    await _quietly(() => store.deleteExcept(null));
  }

  static Future<void> _quietly(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('content store cleanup failed: $e');
    }
  }
}
