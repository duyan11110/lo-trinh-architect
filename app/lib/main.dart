import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme/theme.dart';
import 'content/content_repository.dart';
import 'content/content_update.dart';
import 'content/search_index.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LtaApp(warmSearchIndex: true, checkContentUpdates: true),
    ),
  );
}

class LtaApp extends ConsumerWidget {
  const LtaApp({
    super.key,
    this.locale,
    this.warmSearchIndex = false,
    this.checkContentUpdates = false,
  });

  /// Forced UI locale; `null` follows the system (falls back to `vi`).
  final Locale? locale;

  /// Build the S9 index in the background right after launch (docs/07 §8)
  /// instead of on the first visit to Tìm. Off in widget tests.
  final bool warmSearchIndex;

  /// Check `manifest.json` in the background at launch when the last check
  /// is older than 24 hours (docs/07 §7). Off in tests (no network).
  final bool checkContentUpdates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (warmSearchIndex) {
      ref.listen(searchIndexProvider, (_, next) {
        if (next.hasError) debugPrint('search index failed: ${next.error}');
      });
    }
    if (checkContentUpdates) {
      ref.listen(contentProvider, (prev, next) {
        if (prev?.hasValue != true && next.hasValue) {
          ref.read(contentUpdateProvider.notifier).checkInBackground();
        }
      });
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => L.of(context).appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
