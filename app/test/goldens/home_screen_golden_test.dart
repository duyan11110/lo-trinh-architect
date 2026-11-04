// S1 Học tiếp (M2 first golden, DECISIONS.md E4): fresh install, light/dark.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lta_app/features/home/home_screen.dart';

import '../helpers.dart';

void main() {
  goldenTest(
    'S1 home screen',
    fileName: 's1_home',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final b in Brightness.values)
          GoldenTestScenario(
            name: '${b.name} · fresh',
            child: SizedBox(
              width: 390,
              height: 844,
              child: ProviderScope(
                overrides: [
                  ...contentOverrides(),
                  ...progressOverrides(memoryDb()),
                ],
                child: themedApp(const HomeScreen(), brightness: b),
              ),
            ),
          ),
      ],
    ),
  );
}
