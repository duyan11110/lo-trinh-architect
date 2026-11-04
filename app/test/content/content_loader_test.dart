// content_loader against the sample fixture (DECISIONS.md E6): the asset
// source and models (M1), and the remote update of docs/07 §7 (M6) over a
// fake HTTP client — manifest, sha256 mismatch, gunzip/parse errors, store
// failure, atomic switch, fallback to the asset.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/content_loader.dart';
import 'package:lta_app/content/content_store.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/settings_repository.dart';

import '../fixtures/fake_remote.dart';
import '../helpers.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.raw);
  final String raw;
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(raw)));
  }
}

class _FailingStore extends MemoryContentStore {
  @override
  Future<void> write(int version, String json) async =>
      throw StateError('disk full');
}

class _CountingAsset implements ContentSource {
  int reads = 0;
  @override
  Future<String> read() async {
    reads++;
    return sampleJson();
  }
}

Matcher _fails(ContentUpdateFailure f) => throwsA(
  isA<ContentUpdateException>().having((e) => e.failure, 'failure', f),
);

void main() {
  test('AssetContentSource reads assets/content/content.json', () async {
    final bundle = _Bundle(sampleJson());
    final c = await const ContentLoader(
      background: false,
    ).load(AssetContentSource(bundle: bundle));
    expect(bundle.requested, [AssetContentSource.defaultPath]);
    expect(c.meta.contentVersion, greaterThanOrEqualTo(1));
  });

  test('sample parses into models matching the schema shape', () {
    final c = sampleContent();
    expect(c.meta.langs, containsAll(['vi', 'en']));
    expect(c.stages, hasLength(5));
    expect(c.lessons, isNotEmpty);
    expect(c.glossary, isNotEmpty);
    for (final l in c.lessons.values) {
      expect(l.sectionsVi.length, l.sectionsEn.length);
      expect(
        l.sectionsEn.map((s) => s.n),
        List.generate(l.sectionsEn.length, (i) => i + 1),
      );
      final module = c.module(l.moduleKey);
      expect(module, isNotNull, reason: l.moduleKey);
      expect(module!.lessons.map((r) => r.id), contains(l.id));
    }
    for (final q in c.quizzes.values) {
      expect(c.lessons, contains(q.lesson));
      expect(q.questions, isNotEmpty);
    }
  });

  test('lessonTitle knows ids from the track tree that have no body', () {
    final c = sampleContent();
    final refs = c.tracks
        .expand((t) => t.levels)
        .expand((l) => l.modules)
        .expand((m) => m.lessons)
        .where((r) => !c.lessons.containsKey(r.id));
    expect(refs, isNotEmpty);
    expect(c.lessonTitle(refs.first.id), refs.first.title);
    expect(c.lessonTitle('nope.l9.missing'), isNull);
  });

  test('malformed content fails with FormatException', () {
    expect(() => parseContent('{"meta": {}}'), throwsFormatException);
  });

  group('remote update (docs/07 §7)', () {
    late AppDatabase db;
    late MemoryContentStore store;
    late SettingsRepository settings;

    setUp(() {
      db = memoryDb();
      store = MemoryContentStore();
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    ContentUpdater updater(FakeRemote remote, {ContentStore? s}) =>
        ContentUpdater(
          remote: RemoteContent(remote.client(), defaultRemoteBaseUrl),
          store: s ?? store,
          db: db,
          clock: FixedClock(testEpoch),
          loader: const ContentLoader(background: false),
        );

    Future<ContentManifest> manifestOf(FakeRemote remote) =>
        RemoteContent(remote.client(), defaultRemoteBaseUrl).manifest();

    Future<void> expectUntouched() async {
      expect(await settings.get(SettingKeys.contentSource), isNull);
      expect(await settings.get(SettingKeys.contentVersion), isNull);
      expect(store.files, isEmpty);
      final events = await db.select(db.event).get();
      expect(events.where((e) => e.kind == 'content_updated'), isEmpty);
    }

    test('manifest is read from remote_base_url', () async {
      final remote = FakeRemote(
        version: 2,
        base: sampleJson(),
        added: ['x.l1.a', 'x.l1.b'],
        changed: ['y'],
      );
      final m = await manifestOf(remote);
      expect(
        remote.requests.single.toString(),
        '${defaultRemoteBaseUrl}manifest.json',
      );
      expect(m.contentVersion, 2);
      expect(m.lessonsAdded, hasLength(2));
      expect(m.lessonsChanged, ['y']);
      expect(m.sha256, hasLength(64));
    });

    test('sha256 ok → stored, settings switched together, event', () async {
      final remote = FakeRemote(version: 2, base: sampleJson());
      store.files[1] = 'old download';
      final c = await updater(remote).apply(await manifestOf(remote));
      expect(c.meta.contentVersion, 2);
      expect(store.files.keys, [2], reason: 'older versions are dropped');
      expect(await settings.get(SettingKeys.contentSource), 'remote');
      expect(await settings.get(SettingKeys.contentVersion), '2');
      final events = await db.select(db.event).get();
      expect(events.single.kind, 'content_updated');
      expect(events.single.value, 2);

      final asset = _CountingAsset();
      final resolved = ResolvedContentSource(
        asset: asset,
        store: store,
        settings: settings,
      );
      final loaded = await const ContentLoader(background: false).load(resolved);
      expect(loaded.meta.contentVersion, 2);
      expect(asset.reads, 0);
    });

    test('sha256 mismatch → checksum failure, old content kept', () async {
      final remote = FakeRemote(version: 2, base: sampleJson(), badChecksum: true);
      await expectLater(
        updater(remote).apply(await manifestOf(remote)),
        _fails(ContentUpdateFailure.checksum),
      );
      await expectUntouched();
    });

    test('gunzip error → corrupt, old content kept', () async {
      final remote = FakeRemote(
        version: 2,
        archive: utf8.encode('not a gzip stream'),
      );
      await expectLater(
        updater(remote).apply(await manifestOf(remote)),
        _fails(ContentUpdateFailure.corrupt),
      );
      await expectUntouched();
    });

    test('content that does not parse → corrupt, old content kept', () async {
      final remote = FakeRemote(version: 2, json: '{"meta": {}}');
      await expectLater(
        updater(remote).apply(await manifestOf(remote)),
        _fails(ContentUpdateFailure.corrupt),
      );
      await expectUntouched();
    });

    test('content_version differing from the manifest → corrupt', () async {
      final remote = FakeRemote(version: 3, json: withContentVersion(sampleJson(), 2));
      await expectLater(
        updater(remote).apply(await manifestOf(remote)),
        _fails(ContentUpdateFailure.corrupt),
      );
      await expectUntouched();
    });

    test('download error → network failure, old content kept', () async {
      final remote = FakeRemote(version: 2, base: sampleJson(), archiveStatus: 503);
      await expectLater(
        updater(remote).apply(await manifestOf(remote)),
        _fails(ContentUpdateFailure.network),
      );
      await expectUntouched();
      await expectLater(
        RemoteContent(offlineClient(), defaultRemoteBaseUrl).manifest(),
        _fails(ContentUpdateFailure.network),
      );
    });

    test('store write failure → settings untouched (atomic)', () async {
      final remote = FakeRemote(version: 2, base: sampleJson());
      await expectLater(
        updater(remote, s: _FailingStore()).apply(await manifestOf(remote)),
        _fails(ContentUpdateFailure.storage),
      );
      expect(await settings.get(SettingKeys.contentSource), isNull);
      expect(await settings.get(SettingKeys.contentVersion), isNull);
    });

    test('a failed second update keeps the first download', () async {
      final first = FakeRemote(version: 2, base: sampleJson());
      await updater(first).apply(await manifestOf(first));
      final second = FakeRemote(version: 3, base: sampleJson(), badChecksum: true);
      await expectLater(
        updater(second).apply(await manifestOf(second)),
        _fails(ContentUpdateFailure.checksum),
      );
      expect(await settings.get(SettingKeys.contentVersion), '2');
      expect(store.files.keys, [2]);
    });

    test('resolved source falls back to the asset', () async {
      final asset = _CountingAsset();
      final resolved = ResolvedContentSource(
        asset: asset,
        store: store,
        settings: settings,
      );
      await resolved.read();
      expect(asset.reads, 1, reason: 'asset by default');
      await settings.set(SettingKeys.contentSource, 'remote');
      await settings.set(SettingKeys.contentVersion, '7');
      await resolved.read();
      expect(asset.reads, 2, reason: 'remote version not stored');
    });

    test('useBundled switches back to the asset, drops downloads', () async {
      final remote = FakeRemote(version: 2, base: sampleJson());
      final u = updater(remote);
      await u.apply(await manifestOf(remote));
      await u.useBundled();
      expect(await settings.get(SettingKeys.contentSource), 'asset');
      expect(store.files, isEmpty);
    });

    test('SqliteContentStore keeps one text per version', () async {
      final s = SqliteContentStore(
        ContentCacheDatabase(NativeDatabase.memory()),
      );
      addTearDown(s.close);
      expect(await s.read(1), isNull);
      await s.write(1, 'one');
      await s.write(2, 'two');
      await s.write(2, 'two again');
      expect(await s.read(2), 'two again');
      await s.deleteExcept(2);
      expect(await s.read(1), isNull);
      await s.deleteExcept(null);
      expect(await s.read(2), isNull);
    });
  });
}
