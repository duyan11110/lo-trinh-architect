// M0: app boots into the shell with four bottom-nav destinations.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/main.dart';

import 'helpers.dart';

void main() {
  testWidgets('opens to the shell with bottom nav (vi)', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    for (final label in ['Học tiếp', 'Lộ trình', 'Ôn tập', 'Tìm']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('tapping a destination switches tab', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: const LtaApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });
}
