// M6 Done (docs/07 §11): "cập nhật thất bại giữ bản cũ" at widget level —
// the real app, in-memory database and content store, fake HTTP client.
// integration_test/content_update_test.dart runs the same steps
// (test/flows/content_update_flow.dart) on the platform database.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/content_store.dart';
import 'package:lta_app/content/content_update.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/settings_repository.dart';

import '../fixtures/fake_remote.dart';
import '../flows/content_update_flow.dart';
import '../helpers.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  testWidgets('failed update keeps the old content; a good one switches', (
    tester,
  ) async {
    final store = MemoryContentStore();
    final client = SwitchableClient(offlineClient());
    final bundled = sampleJson();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...updateOverrides(db: db, bundled: bundled, store: store, client: client),
          clockProvider.overrideWithValue(FixedClock(testEpoch)),
        ],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
    await runContentUpdateFlow(
      tester,
      db: db,
      store: store,
      client: client,
      bundled: bundled,
      v1: sampleContent().meta.contentVersion,
    );
    final events = await db.select(db.event).get();
    expect(events.where((e) => e.kind == 'content_updated'), hasLength(1));
  });

  testWidgets('background check: at most once per 24 h, S1 line → S10', (
    tester,
  ) async {
    final store = MemoryContentStore();
    final clock = FixedClock(testEpoch);
    final remote = FakeRemote(version: 2, base: sampleJson());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...updateOverrides(
            db: db,
            bundled: sampleJson(),
            store: store,
            client: remote.client(),
          ),
          clockProvider.overrideWithValue(clock),
        ],
        child: const LtaApp(locale: Locale('vi'), checkContentUpdates: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(remote.requests, hasLength(1));
    expect(find.text('Có nội dung mới (v2)'), findsOneWidget);
    expect(
      await SettingsRepository(db).get(SettingKeys.contentCheckedAt),
      isNotNull,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LtaApp)),
    );
    clock.advance(const Duration(hours: 23));
    await container.read(contentUpdateProvider.notifier).checkInBackground();
    expect(remote.requests, hasLength(1), reason: 'checked < 24 h ago');

    await tester.tap(find.text('Cập nhật'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra bản mới'), findsOneWidget);
    expect(remote.requests, hasLength(2), reason: '/settings/content checks');
  });
}
