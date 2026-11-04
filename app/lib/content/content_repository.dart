// Content access for the UI — docs/07 §7–§8. Riverpod providers over the
// loader, the glossary matcher per language and a parsed-lesson LRU cache.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/text.dart';
import '../progress/settings_repository.dart';
import 'content_loader.dart';
import 'content_store.dart';
import 'glossary_matcher.dart';
import 'markdown/blocks.dart';
import 'markdown/grammar.dart';
import 'models/models.dart';

/// Downloaded content versions (docs/07 §7). Override in tests.
final contentStoreProvider = Provider<ContentStore>((ref) {
  final store = SqliteContentStore(ContentCacheDatabase());
  ref.onDispose(store.close);
  return store;
});

/// What `settings.content_source` points at, falling back to the asset.
final contentSourceProvider = Provider<ContentSource>(
  (ref) => ResolvedContentSource(
    asset: AssetContentSource(),
    store: ref.watch(contentStoreProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final contentLoaderProvider = Provider<ContentLoader>(
  (ref) => const ContentLoader(),
);

/// The loaded, immutable content. Override with a preloaded value in tests.
final contentProvider = FutureProvider<Content>(
  (ref) => ref.watch(contentLoaderProvider).load(ref.watch(contentSourceProvider)),
);

/// Content language chosen with the VI|EN toggle or in S10; `null` follows
/// the UI locale. Persisted in `settings.content_lang`.
class ContentLangNotifier extends Notifier<ContentLang?> {
  @override
  ContentLang? build() {
    final v = ref.watch(settingsProvider).value?[SettingKeys.contentLang];
    return v == null ? null : ContentLang.fromCode(v);
  }

  void set(ContentLang lang) {
    state = lang;
    _persist(ref, SettingKeys.contentLang, lang.name);
  }
}

void _persist(Ref ref, String key, String value) {
  ref.read(settingsRepositoryProvider).set(key, value).catchError(
    (Object e) => debugPrint('settings write failed: $e'),
  );
}

final contentLangProvider = NotifierProvider<ContentLangNotifier, ContentLang?>(
  ContentLangNotifier.new,
);

/// Effective content language for [context].
ContentLang effectiveLang(WidgetRef ref, BuildContext context) =>
    ref.watch(contentLangProvider) ??
    ContentLang.fromCode(Localizations.localeOf(context).languageCode);

/// Reading font step (docs/05 S3 `Aa`: 4 steps 15/17/19/21 sp) and line
/// height (2 steps). Persisted in `settings.font_scale` / `line_height`.
class ReadingPrefs {
  const ReadingPrefs({this.fontStep = defaultStep, this.lineStep = 0});

  static const steps = [
    LtaText.readingMin,
    LtaText.readingMin + 2,
    LtaText.readingMax - 2,
    LtaText.readingMax,
  ];
  static const defaultStep = 1;

  final int fontStep;
  final int lineStep;

  double get fontSize => steps[fontStep.clamp(0, steps.length - 1)];

  double get lineHeight => LtaText.readingLineHeights[lineStep.clamp(
    0,
    LtaText.readingLineHeights.length - 1,
  )];
}

class ReadingPrefsNotifier extends Notifier<ReadingPrefs> {
  @override
  ReadingPrefs build() {
    final s = ref.watch(settingsProvider).value ?? const {};
    int? read(String key, int max) {
      final v = int.tryParse(s[key] ?? '');
      return v == null || v < 0 || v > max ? null : v;
    }

    return ReadingPrefs(
      fontStep:
          read(SettingKeys.fontScale, ReadingPrefs.steps.length - 1) ??
          ReadingPrefs.defaultStep,
      lineStep: read(
            SettingKeys.lineHeight,
            LtaText.readingLineHeights.length - 1,
          ) ??
          0,
    );
  }

  void setFontStep(int step) {
    state = ReadingPrefs(fontStep: step, lineStep: state.lineStep);
    _persist(ref, SettingKeys.fontScale, '$step');
  }

  void setLineStep(int step) {
    state = ReadingPrefs(fontStep: state.fontStep, lineStep: step);
    _persist(ref, SettingKeys.lineHeight, '$step');
  }
}

/// `settings.theme`: system | light | dark (S10).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final v = ref.watch(settingsProvider).value?[SettingKeys.theme];
    return ThemeMode.values.where((m) => m.name == v).firstOrNull ??
        ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    _persist(ref, SettingKeys.theme, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final readingPrefsProvider = NotifierProvider<ReadingPrefsNotifier, ReadingPrefs>(
  ReadingPrefsNotifier.new,
);

/// One glossary matcher per language and content load.
final glossaryMatcherProvider = Provider.family<GlossaryMatcher, ContentLang>((
  ref,
  lang,
) {
  final content = ref.watch(contentProvider).requireValue;
  return GlossaryMatcher(content.glossary, lang: lang);
});

@immutable
class ParsedSection {
  const ParsedSection(this.section, this.blocks);
  final LessonSection section;
  final List<ProseBlock> blocks;
}

/// Sections are parsed to blocks only when a lesson opens; keeps the last
/// [capacity] (lesson, language) pairs (docs/07 §8: LRU of 10 lessons).
class ProseCache {
  ProseCache({this.capacity = 10});

  final int capacity;
  final _cache = <(String, ContentLang, int), List<ParsedSection>>{};

  List<ParsedSection> get(Lesson lesson, ContentLang lang, GlossaryMatcher m) {
    final key = (lesson.id, lang, lesson.contentVersion);
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    final parser = ProseParser(matcher: m);
    final parsed = List<ParsedSection>.unmodifiable([
      for (final s in lesson.sections(lang)) ParsedSection(s, parser.parse(s.md)),
    ]);
    _cache[key] = parsed;
    if (_cache.length > capacity) _cache.remove(_cache.keys.first);
    return parsed;
  }
}

final proseCacheProvider = Provider<ProseCache>((ref) {
  ref.watch(contentProvider);
  return ProseCache();
});
