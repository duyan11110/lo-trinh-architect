// docs/07 §9 Unit `glossary_matcher` (tools/SPEC.md A.2): longest phrase,
// plurals, ALL-CAPS tokens, inline code skipped, Unicode word boundaries.
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/glossary_matcher.dart';
import 'package:lta_app/content/markdown/blocks.dart';
import 'package:lta_app/content/markdown/grammar.dart';
import 'package:lta_app/content/models/models.dart';

GlossaryEntry _e(
  String term,
  String en, {
  String? vi,
  List<String> aliases = const [],
}) => GlossaryEntry(
  term: term,
  en: en,
  viKeep: vi == null,
  vi: vi ?? en,
  shortVi: 's',
  shortEn: 's',
  introducedIn: 'foundation.l1.x',
  aliases: aliases,
);

final _entries = [
  _e('map', 'map'),
  _e('hash-map', 'hash map'),
  _e('commit', 'commit'),
  _e('dns', 'DNS'),
  _e('dependency', 'dependency'),
  _e('process', 'process'),
  _e('transaction', 'transaction', vi: 'giao dịch'),
  _e('garbage-collector', 'garbage collector', aliases: ['gc']),
  _e('k8s-service', 'Kubernetes Service', vi: 'Service'),
  _e('index', 'index'),
];

List<String> _terms(GlossaryMatcher m, String text) => [
  for (final x in m.match(text))
    '${x.entry.term}:${text.substring(x.start, x.end)}',
];

void main() {
  final en = GlossaryMatcher(_entries, lang: ContentLang.en);
  final vi = GlossaryMatcher(_entries, lang: ContentLang.vi);

  test('longest phrase wins at a position', () {
    expect(_terms(en, 'A hash map is a map.'), [
      'hash-map:hash map',
      'map:map',
    ]);
  });

  test('simple English plurals: +s, +es, y→ies', () {
    expect(_terms(en, 'Two hash maps, processes and dependencies.'), [
      'hash-map:hash maps',
      'process:processes',
      'dependency:dependencies',
    ]);
  });

  test('case-insensitive, aliases included', () {
    expect(_terms(en, 'The Commit ran the GC.'), [
      'commit:Commit',
      'garbage-collector:GC',
    ]);
  });

  test('ALL-CAPS token ≥ 3 letters only matches an all-caps entry', () {
    expect(_terms(en, 'Run COMMIT; ask DNS; dns too.'), [
      'dns:DNS',
      'dns:dns',
    ]);
  });

  test('word boundaries: no match inside a longer word', () {
    expect(_terms(en, 'mapping, remap, indexes, reindex'), ['index:indexes']);
  });

  test('vi form only for Vietnamese text', () {
    expect(_terms(en, 'A Service object.'), isEmpty);
    expect(_terms(vi, 'Một Service và một giao dịch.'), [
      'k8s-service:Service',
      'transaction:giao dịch',
    ]);
  });

  test('Unicode boundaries with Vietnamese diacritics', () {
    expect(_terms(vi, 'giao dịchx xgiao dịch (giao dịch).'), [
      'transaction:giao dịch',
    ]);
    // A Vietnamese letter right after an English term blocks the match.
    expect(_terms(vi, 'mapđ map'), ['map:map']);
    expect(_terms(vi, 'đmap map'), ['map:map']);
  });

  test('inline code and [[id]] are never matched (via the parser)', () {
    final p = ProseParser(matcher: en).parse(
      'A `hash map` call, [[foundation.l1.map]] and a map.',
    );
    final runs = (p.single as ParagraphBlock).inlines;
    final terms = runs.whereType<TextRun>().where((r) => r.term != null);
    expect(terms.map((r) => r.text), ['map']);
  });

  test('exact() for bold text strips parentheses', () {
    expect(en.exact('hash map (bảng băm)')?.term, 'hash-map');
    expect(en.exact('hash map lookup'), isNull);
    expect(en.exact('COMMIT'), isNull);
  });
}
