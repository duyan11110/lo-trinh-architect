// S2 Lộ trình (M4 golden, DECISIONS.md E4): sample content, fresh install,
// light/dark — stage 0 open, the module of "Học tiếp" open, "sắp có" rows.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lta_app/features/path/path_screen.dart';

import '../helpers.dart';

void main() {
  goldenTest(
    'S2 path screen',
    fileName: 's2_path',
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
                child: themedApp(const PathScreen(), brightness: b),
              ),
            ),
          ),
      ],
    ),
  );
}
