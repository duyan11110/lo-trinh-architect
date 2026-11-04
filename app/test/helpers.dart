// Shared test helpers: the sample fixture (docs/07 §9) and an app harness.
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lta_app/app/theme/theme.dart';
import 'package:lta_app/content/content_loader.dart';
import 'package:lta_app/content/content_repository.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/l10n/app_localizations.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/progress_repository.dart';

const samplePath = 'test/fixtures/content.sample.json';

String sampleJson() => File(samplePath).readAsStringSync();

Content sampleContent() => parseContent(sampleJson());

/// In-memory [ContentSource].
class StringContentSource implements ContentSource {
  StringContentSource(this.raw);
  final String raw;
  @override
  Future<String> read() async => raw;
}

/// Provider overrides that serve [raw] (default: the sample) synchronously
/// parsed — no isolate inside fake-async widget tests.
List<Override> contentOverrides([String? raw]) => [
  contentSourceProvider.overrideWithValue(
    StringContentSource(raw ?? sampleJson()),
  ),
  contentLoaderProvider.overrideWithValue(
    const ContentLoader(background: false),
  ),
];

/// Overrides serving an already built [Content] (fixture builder, E6).
List<Override> builtContentOverrides(Content content) => [
  contentProvider.overrideWith((ref) => content),
];

/// Fixed test time (DECISIONS.md E7).
final testEpoch = DateTime.utc(2026, 11, 5, 8);

/// In-memory progress database; close it in `tearDown`/`addTearDown`.
AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Synchronous stream teardown: no zero-duration timers left in fake async.
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

/// Overrides serving [db] and a fixed [clock].
List<Override> progressOverrides(AppDatabase db, {Clock? clock}) => [
  appDatabaseProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(clock ?? FixedClock(testEpoch)),
];

/// Wraps [child] in MaterialApp with the real themes and localizations.
Widget themedApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('vi'),
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildTheme(brightness),
  locale: locale,
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  // Goldens put the app in a phone-sized box on a large surface: the window
  // width the responsive layout reads (docs/05 §9) is the box's.
  builder: (context, app) => LayoutBuilder(
    builder: (context, box) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: box.biggest),
      child: app!,
    ),
  ),
  home: child,
);
