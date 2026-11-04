// docs/07 §9/§11 M6 "cập nhật thất bại giữ bản cũ": Học tiếp → ⚙ Cài đặt →
// Kiểm tra bản mới → Cập nhật with a broken download (sha256 mismatch) →
// the failure message names the old version, the app still reads it and
// nothing was switched or stored; then a good download → Học tiếp on the
// new version. Shared by the widget-level test
// (test/features/content_update_test.dart) and integration_test/. Web-safe.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lta_app/content/content_loader.dart';
import 'package:lta_app/content/content_repository.dart';
import 'package:lta_app/content/content_store.dart';
import 'package:lta_app/content/content_update.dart';
import 'package:lta_app/features/home/home_screen.dart';
import 'package:lta_app/features/settings/settings_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/progress_repository.dart';
import 'package:lta_app/progress/settings_repository.dart';

import '../fixtures/fake_remote.dart';
import 'everyday_flow.dart' show pumpUntilFound;

/// Serves the requests of the current step; swapped between steps.
class SwitchableClient extends http.BaseClient {
  SwitchableClient(this.inner);
  http.Client inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      inner.send(request);
}

class _Source implements ContentSource {
  _Source(this.raw);
  final String raw;
  @override
  Future<String> read() async => raw;
}

/// Overrides wiring the real resolved source to [bundled] (the "asset"),
/// an in-memory [store] and [client].
List<Override> updateOverrides({
  required AppDatabase db,
  required String bundled,
  required ContentStore store,
  required http.Client client,
}) => [
  appDatabaseProvider.overrideWithValue(db),
  contentStoreProvider.overrideWithValue(store),
  httpClientProvider.overrideWithValue(client),
  contentLoaderProvider.overrideWithValue(const ContentLoader(background: false)),
  contentSourceProvider.overrideWith(
    (ref) => ResolvedContentSource(
      asset: _Source(bundled),
      store: store,
      settings: ref.watch(settingsRepositoryProvider),
    ),
  ),
];

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(LtaApp)));

/// Runs the flow on a pumped [LtaApp] (locale vi) showing content [v1].
Future<void> runContentUpdateFlow(
  WidgetTester tester, {
  required AppDatabase db,
  required MemoryContentStore store,
  required SwitchableClient client,
  required String bundled,
  required int v1,
}) async {
  final settings = SettingsRepository(db);
  await pumpUntilFound(tester, find.byType(HomeScreen));
  expect((await _container(tester).read(contentProvider.future)).meta.contentVersion, v1);

  // 1. Broken download: sha256 of the .gz does not match the manifest.
  client.inner = FakeRemote(version: v1 + 1, base: bundled, badChecksum: true).client();
  await _tap(tester, find.byIcon(Icons.settings_rounded));
  expect(find.byType(SettingsScreen), findsOneWidget);
  await _tap(tester, find.text('Kiểm tra bản mới'));
  await pumpUntilFound(tester, find.text('Có nội dung mới (v${v1 + 1})'));
  await _tap(tester, find.text('Cập nhật'));
  await pumpUntilFound(
    tester,
    find.text('Không tải được bản mới. Bạn vẫn dùng bản v$v1 bình thường.'),
  );
  expect(find.byType(SettingsScreen), findsOneWidget, reason: 'stays on S10');
  expect(find.textContaining('v$v1 ·'), findsOneWidget);
  expect((await _container(tester).read(contentProvider.future)).meta.contentVersion, v1);
  expect(await settings.get(SettingKeys.contentSource), isNull);
  expect(await settings.get(SettingKeys.contentVersion), isNull);
  expect(store.files, isEmpty);

  // 2. Lost connection while updating: same outcome.
  client.inner = offlineClient();
  await _tap(tester, find.text('Cập nhật'));
  await pumpUntilFound(
    tester,
    find.text('Không tải được bản mới. Bạn vẫn dùng bản v$v1 bình thường.'),
  );
  expect(store.files, isEmpty);

  // 3. A good download switches and returns to Học tiếp.
  client.inner = FakeRemote(version: v1 + 1, base: bundled).client();
  await _tap(tester, find.text('Kiểm tra bản mới'));
  await pumpUntilFound(tester, find.text('Có nội dung mới (v${v1 + 1})'));
  await _tap(tester, find.text('Cập nhật'));
  await pumpUntilFound(tester, find.byType(HomeScreen));
  expect(find.byType(SettingsScreen), findsNothing);
  expect(
    (await _container(tester).read(contentProvider.future)).meta.contentVersion,
    v1 + 1,
  );
  expect(await settings.get(SettingKeys.contentSource), 'remote');
  expect(store.files.keys, [v1 + 1]);
}
