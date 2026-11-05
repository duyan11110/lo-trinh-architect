// docs/07 §11 M6 integration "cập nhật thất bại giữ bản cũ": the real app on
// the platform database, the bundled asset as the old content, an in-memory
// content store and a fake HTTP client (never the network). Same steps as
// the widget-level test (integration_test/flows/content_update_flow.dart).
// CI: `flutter drive --driver=test_driver/integration_test.dart
// --target=integration_test/content_update_test.dart -d chrome` (E7).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lta_app/content/content_loader.dart';
import 'package:lta_app/content/content_store.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/database.dart';

import 'flows/fake_remote.dart';
import 'flows/content_update_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failed update keeps the old content', (tester) async {
    final db = AppDatabase();
    for (final table in db.allTables) {
      await db.delete(table).go();
    }
    final bundled = await rootBundle.loadString(AssetContentSource.defaultPath);
    final store = MemoryContentStore();
    final client = SwitchableClient(offlineClient());
    await tester.pumpWidget(
      ProviderScope(
        overrides: updateOverrides(
          db: db,
          bundled: bundled,
          store: store,
          client: client,
        ),
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await runContentUpdateFlow(
      tester,
      db: db,
      store: store,
      client: client,
      bundled: bundled,
      v1: parseContent(bundled).meta.contentVersion,
    );
    // Unmount first: open query streams keep the web (WASM worker) database
    // from closing.
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
