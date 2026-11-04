// Golden config — DECISIONS.md E4: alchemist, CI goldens only
// (platformGoldens disabled), compared on Linux CI.
import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: () async => testMain(),
  );
}
