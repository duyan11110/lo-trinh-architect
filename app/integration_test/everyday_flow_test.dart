// docs/07 §9 integration "Luồng ngày thường": mở app → Học tiếp → đọc tới
// cuối → quiz 6 câu (1 sai) → kết quả → Ôn hôm nay có 1 câu after the clock
// moves one day (injected clock, DECISIONS.md E7).
// Real app, bundled sample content (DECISIONS.md E6), platform database
// (WASM on web). CI: `flutter drive --driver=test_driver/integration_test.dart
// --target=integration_test/everyday_flow_test.dart -d chrome` (E7).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/progress_repository.dart';

import '../test/flows/everyday_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('everyday flow: open → read → quiz → result → review', (tester) async {
    final db = AppDatabase();
    final clock = FixedClock(DateTime.now());
    // Start from a fresh install.
    for (final table in db.allTables) {
      await db.delete(table).go();
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
        ],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await runEverydayFlow(tester, db);
    await runReviewNextDay(tester, clock);
    await db.close();
  });
}
