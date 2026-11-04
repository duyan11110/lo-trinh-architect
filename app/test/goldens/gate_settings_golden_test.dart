// M6 goldens (DECISIONS.md E4: first goldens of new screens): S8 Bài cổng
// (stage finished, no attempt yet) and S10 Cài đặt, light/dark.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lta_app/features/gate/gate_intro_screen.dart';
import 'package:lta_app/features/settings/settings_screen.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

void main() {
  GoldenTestGroup group(Widget Function() screen) => GoldenTestGroup(
    columns: 2,
    children: [
      for (final b in Brightness.values)
        GoldenTestScenario(
          name: b.name,
          child: SizedBox(
            width: 390,
            height: 844,
            child: ProviderScope(
              overrides: [
                ...builtContentOverrides(contentWithGate()),
                ...progressOverrides(memoryDb()),
              ],
              child: themedApp(screen(), brightness: b),
            ),
          ),
        ),
    ],
  );

  goldenTest(
    'S8 gate intro',
    fileName: 's8_gate',
    builder: () => group(() => const GateIntroScreen(stage: 0)),
  );

  goldenTest(
    'S10 settings',
    fileName: 's10_settings',
    builder: () => group(() => const SettingsScreen()),
  );
}
