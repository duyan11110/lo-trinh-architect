// S9 full-text search — docs/07 §4 (`search_index` FTS5, tokenizer
// `unicode61 remove_diacritics 0`: Vietnamese diacritics are kept, so "đơn"
// and "don" are different words while case is folded, "ĐƠN" = "đơn"),
// docs/04 §2 (title + sections without code blocks), docs/07 §8 (built in a
// background isolate on first run and whenever the content changes).
//
// Cost on the real content (605 lessons × 2 languages): the Markdown is
// stripped once per content build in `compute`, the rows go in one batch in
// one transaction, and the build is skipped while the stored stamp matches.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/database.dart';
import '../progress/progress_repository.dart';
import 'content_repository.dart';
import 'models/models.dart';

/// `settings` key holding the stamp of the content the index was built from.
const String searchIndexSettingKey = 'search_index_version';

/// Queries shorter than this do not search (docs/05 S9: ≥ 2 characters).
const int searchMinChars = 2;

/// Highlight markers in titles and snippets returned by FTS5.
const String searchMarkStart = '\u0002';
const String searchMarkEnd = '\u0003';

/// One lesson in one language, as sent to the extraction isolate.
typedef SearchSource = ({
  String lessonId,
  String lang,
  String title,
  List<String> sections,
});

/// One `search_index` row.
typedef SearchDoc = ({String lessonId, String lang, String title, String body});

// Punctuation (`*`, `_`, backticks…) needs no stripping: the unicode61
// tokenizer treats it as a separator. Only placeholders whose words would
// pollute the index go: `{{diagram}}`, `[[lesson.id]]`, `<details>` tags.
final _placeholders = RegExp(
  r'\{\{[^}]*\}\}|\[\[[^\]]*\]\]|</?(?:details|summary)[^>]*>',
  caseSensitive: false,
);
final _link = RegExp(r'\[([^\]]*)\]\([^)]*\)');
final _lineMarker = RegExp(r'^\s*(?:#{1,6}|>|[-*+]|\d+\.)\s+');

/// Plain text of a section: no fenced code blocks (docs/04 §2), no diagram
/// or `[[id]]` placeholders, no list/heading markers. Line-based: one pass,
/// no backtracking over whole sections (it runs over ~40 MB of Markdown).
String searchableText(String md) {
  final out = StringBuffer();
  String? fence;
  for (var line in md.split('\n')) {
    final trimmed = line.trimLeft();
    if (fence != null) {
      if (trimmed.startsWith(fence)) fence = null;
      continue;
    }
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      fence = trimmed.substring(0, 3);
      continue;
    }
    if (trimmed.isEmpty) continue;
    line = trimmed.replaceFirst(_lineMarker, '');
    if (line.contains('](')) line = line.replaceAllMapped(_link, (m) => m[1]!);
    if (line.contains('{{') || line.contains('[[') || line.contains('<')) {
      line = line.replaceAll(_placeholders, ' ');
    }
    if (out.isNotEmpty) out.write('\n');
    out.write(line);
  }
  return out.toString();
}

/// Top-level for `compute`.
List<SearchDoc> buildSearchDocs(List<SearchSource> sources) => [
  for (final s in sources)
    (
      lessonId: s.lessonId,
      lang: s.lang,
      title: s.title,
      body: s.sections.map(searchableText).join('\n'),
    ),
];

List<SearchSource> searchSources(Content content) => [
  for (final l in content.lessons.values)
    for (final lang in ContentLang.values)
      (
        lessonId: l.id,
        lang: lang.name,
        title: l.title.of(lang),
        sections: [for (final s in l.sections(lang)) '${s.heading}\n${s.md}'],
      ),
];

/// Identifies one content build.
String searchStamp(Content c) => '${c.meta.contentVersion}|${c.meta.builtAt}';

/// FTS5 MATCH expression for what the learner typed: every word (letters and
/// digits, Unicode-aware, accents kept) as a quoted prefix term, all
/// required. `null` when there is nothing to search for.
String? ftsQuery(String input) {
  if (input.trim().length < searchMinChars) return null;
  final words = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true)
      .allMatches(input)
      .map((m) => m[0]!)
      .toList();
  if (words.isEmpty) return null;
  return words.map((w) => '"$w"*').join(' ');
}

@immutable
class SearchHit {
  const SearchHit({
    required this.lessonId,
    required this.lang,
    required this.title,
    required this.snippet,
  });

  final String lessonId;
  final String lang;

  /// With [searchMarkStart]/[searchMarkEnd] around matched words.
  final String title;
  final String snippet;
}

class LessonSearch {
  LessonSearch(this._db, {this.background = true});

  final AppDatabase _db;

  /// Strip Markdown on a background isolate (`compute`; main isolate on web).
  final bool background;

  Future<String?> _stamp() async => (await (_db.select(
    _db.settings,
  )..where((t) => t.key.equals(searchIndexSettingKey))).getSingleOrNull())?.value;

  /// Builds the index unless it already matches [content]. Returns whether
  /// it was (re)built.
  Future<bool> ensure(Content content) async {
    final stamp = searchStamp(content);
    if (await _stamp() == stamp) return false;
    final sources = searchSources(content);
    final docs = background
        ? await compute(buildSearchDocs, sources)
        : buildSearchDocs(sources);
    await _db.transaction(() async {
      await _db.delete(_db.searchIndex).go();
      await _db.batch((b) {
        b.insertAll(_db.searchIndex, [
          for (final d in docs)
            SearchIndexCompanion.insert(
              lessonId: d.lessonId,
              lang: d.lang,
              title: d.title,
              body: d.body,
            ),
        ]);
      });
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(
              key: const Value(searchIndexSettingKey),
              value: stamp,
            ),
          );
    });
    return true;
  }

  /// Best match first; one hit per lesson, preferring the row in [lang]
  /// when the lesson matches in both languages.
  Future<List<SearchHit>> search(String input, ContentLang lang, {int limit = 200}) async {
    final match = ftsQuery(input);
    if (match == null) return const [];
    final rows = await _db
        .customSelect(
          'SELECT lesson_id, lang, '
          'highlight(search_index, 2, ?1, ?2) AS t, '
          "snippet(search_index, 3, ?1, ?2, '…', 16) AS s "
          'FROM search_index WHERE search_index MATCH ?3 ORDER BY rank LIMIT ?4',
          variables: [
            Variable.withString(searchMarkStart),
            Variable.withString(searchMarkEnd),
            Variable.withString(match),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.searchIndex},
        )
        .get();
    final order = <String>[];
    final hits = <String, SearchHit>{};
    for (final r in rows) {
      final hit = SearchHit(
        lessonId: r.read<String>('lesson_id'),
        lang: r.read<String>('lang'),
        title: r.read<String>('t'),
        snippet: r.read<String>('s'),
      );
      final prev = hits[hit.lessonId];
      if (prev == null) {
        order.add(hit.lessonId);
        hits[hit.lessonId] = hit;
      } else if (prev.lang != lang.name && hit.lang == lang.name) {
        hits[hit.lessonId] = hit;
      }
    }
    return [for (final id in order) hits[id]!];
  }
}

final searchIndexServiceProvider = Provider<LessonSearch>(
  (ref) => LessonSearch(
    ref.watch(appDatabaseProvider),
    background: ref.watch(contentLoaderProvider).background,
  ),
);

/// Completes when the index matches the loaded content (S9 shows "Đang lập
/// chỉ mục…" until then).
final searchIndexProvider = FutureProvider<void>((ref) async {
  final content = await ref.watch(contentProvider.future);
  await ref.watch(searchIndexServiceProvider).ensure(content);
});
