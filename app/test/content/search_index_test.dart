// S9 search (docs/07 §4 FTS5 `unicode61 remove_diacritics 0`, docs/05 S9):
// Markdown stripping, query building, Vietnamese diacritics kept but case
// folded, prefix matching, rebuild only when the content changes.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/content/search_index.dart';
import 'package:lta_app/progress/database.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

Content _content({String vi = '', String en = '', int version = 1}) {
  const module = BModule('backend', 'web', 0, [BLesson('orders')]);
  final base = buildContent(const [module]);
  final id = module.lessonId(module.lessons.single);
  final lesson = stubLesson(id, track: 'backend', module: 'web');
  return Content(
    meta: ContentMeta(
      contentVersion: version,
      builtAt: base.meta.builtAt,
      versions: const {},
      langs: const ['vi', 'en'],
    ),
    stages: base.stages,
    tracks: base.tracks,
    lessons: {
      id: Lesson(
        id: id,
        track: lesson.track,
        level: 1,
        stage: 0,
        module: lesson.module,
        mainPath: true,
        durationMin: 10,
        title: const I18n(vi: 'Tạo đơn hàng', en: 'Creating an order'),
        skills: const [],
        prereqs: const [],
        related: const [],
        vocab: const [],
        exampleTag: 'stage-0',
        sectionsVi: [LessonSection(n: 1, heading: 'Bối cảnh', md: vi)],
        sectionsEn: [LessonSection(n: 1, heading: 'Context', md: en)],
        diagramSvg: null,
        skipNote: null,
        contentVersion: version,
      ),
    },
    quizzes: const {},
    gates: const {},
    glossary: const [],
    skills: const [],
  );
}

void main() {
  late AppDatabase db;
  late LessonSearch index;
  setUp(() {
    db = memoryDb();
    index = LessonSearch(db, background: false);
  });
  tearDown(() => db.close());

  group('searchableText', () {
    test('drops fenced code, diagram, [[id]], markup', () {
      const md =
          '## Tiêu đề\n**Header** `Content-Length` [[foundation.l1.x]] {{diagram}}\n'
          '```bash file=a.sh tag=stage-0 lines=1-2\ncurl secretword\n```\n'
          '- một ý\n<details><summary>Gợi ý</summary>đáp</details>';
      final t = searchableText(md);
      expect(t, isNot(contains('secretword')));
      expect(t, isNot(contains('foundation.l1.x')));
      expect(t, isNot(contains('diagram')));
      expect(t, isNot(contains('<details>')));
      expect(t, contains('Tiêu đề'));
      expect(t, contains('Content-Length'));
      expect(t, contains('một ý'));
      expect(t, contains('Gợi ý'));
    });
  });

  group('ftsQuery', () {
    test('needs ≥ 2 characters', () {
      expect(ftsQuery(''), isNull);
      expect(ftsQuery(' đ '), isNull);
      expect(ftsQuery('đơ'), '"đơ"*');
    });

    test('every word a quoted prefix, punctuation dropped', () {
      expect(ftsQuery('đơn hàng'), '"đơn"* "hàng"*');
      expect(ftsQuery('Content-Length: "x" OR'), '"Content"* "Length"* "x"* "OR"*');
      expect(ftsQuery('--'), isNull);
    });
  });

  group('FTS with Vietnamese diacritics', () {
    setUp(() async {
      await index.ensure(
        _content(
          vi: 'Khi khách đặt **đơn hàng**, server trả status code 201. '
              'Quả dâu không phải dấu.',
          en: 'When a customer places an order the server returns 201.',
        ),
      );
    });

    Future<List<String>> ids(String q, [ContentLang lang = ContentLang.vi]) async =>
        [for (final h in await index.search(q, lang)) '${h.lessonId}/${h.lang}'];

    test('accented query finds accented words', () async {
      expect(await ids('đơn hàng'), ['backend.l1.orders/vi']);
      expect(await ids('dấu'), hasLength(1));
      expect(await ids('dâu'), hasLength(1));
    });

    test('case is folded for Vietnamese letters too', () async {
      expect(await ids('ĐƠN HÀNG'), ['backend.l1.orders/vi']);
      expect(await ids('Đơn'), hasLength(1));
    });

    test('prefix of an accented word', () async {
      expect(await ids('hà'), hasLength(1));
      expect(await ids('đơ'), hasLength(1));
    });

    test('unaccented query does not match accented words (diacritics kept)', () async {
      expect(await ids('don hang'), isEmpty);
      expect(await ids('khach'), isEmpty);
      // "dau" is a different word from both "dấu" and "dâu".
      expect(await ids('dau'), isEmpty);
    });

    test('unaccented English terms are found in either language', () async {
      expect(await ids('status code'), ['backend.l1.orders/vi']);
      // Matches only in EN → the EN row is returned.
      expect(await ids('customer'), ['backend.l1.orders/en']);
      // Matches both → the row in the reading language.
      expect(await ids('server', ContentLang.en), ['backend.l1.orders/en']);
      expect(await ids('server', ContentLang.vi), ['backend.l1.orders/vi']);
    });

    test('title is searchable and highlighted', () async {
      final hit = (await index.search('tạo', ContentLang.vi)).single;
      expect(hit.title, '${searchMarkStart}Tạo$searchMarkEnd đơn hàng');
    });

    test('snippet highlights the match', () async {
      final hit = (await index.search('201', ContentLang.vi)).single;
      expect(hit.snippet, contains('${searchMarkStart}201$searchMarkEnd'));
    });
  });

  test('rebuilds only when the content changes', () async {
    expect(await index.ensure(_content(vi: 'alpha')), isTrue);
    expect(await index.ensure(_content(vi: 'beta')), isFalse);
    expect(await index.search('beta', ContentLang.vi), isEmpty);
    expect(await index.ensure(_content(vi: 'beta', version: 2)), isTrue);
    expect(await index.search('alpha', ContentLang.vi), isEmpty);
    expect(await index.search('beta', ContentLang.vi), hasLength(1));
    expect((await db.select(db.searchIndex).get()).length, 2);
  });

  test('sample content: one row per lesson and language, code not indexed', () async {
    final content = sampleContent();
    await index.ensure(content);
    expect(
      (await db.select(db.searchIndex).get()).length,
      content.lessons.length * 2,
    );
    expect(await index.search('response', ContentLang.vi), hasLength(1));
  });

  test('605 sample-sized lessons × 2 languages index in one pass', () async {
    // Every lesson carries the sample lesson's full sections (real size).
    final sample = sampleContent().lessons.values.single;
    final modules = [
      for (var m = 0; m < 55; m++)
        BModule('t${m % 7}', 'm$m', m % 5, [
          for (var i = 0; i < 11; i++) BLesson('l$m-$i'),
        ]),
    ];
    final base = buildContent(modules);
    final content = Content(
      meta: base.meta,
      stages: base.stages,
      tracks: base.tracks,
      lessons: {
        for (final l in base.lessons.values)
          l.id: Lesson(
            id: l.id,
            track: l.track,
            level: 1,
            stage: l.stage,
            module: l.module,
            mainPath: true,
            durationMin: 10,
            title: l.title,
            skills: const [],
            prereqs: const [],
            related: const [],
            vocab: const [],
            exampleTag: l.exampleTag,
            sectionsVi: sample.sectionsVi,
            sectionsEn: sample.sectionsEn,
            diagramSvg: null,
            skipNote: null,
            contentVersion: 1,
          ),
      },
      quizzes: const {},
      gates: const {},
      glossary: const [],
      skills: const [],
    );
    expect(content.lessons.length, 605);
    final sw = Stopwatch()..start();
    await index.ensure(content);
    final built = sw.elapsed;
    final hits = await index.search('response', ContentLang.vi);
    sw.stop();
    debugPrint('search index: build $built, build+query ${sw.elapsed}');
    expect((await db.select(db.searchIndex).get()).length, 1210);
    expect(hits, hasLength(200));
    expect(sw.elapsed, lessThan(const Duration(seconds: 30)));
  });
}
