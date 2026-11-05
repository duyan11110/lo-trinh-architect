// Lazy decoding of content.json (docs/07 §8): the byte scanner must read the
// document exactly like jsonDecode, keeping only lesson `sections` and
// `diagram_svg` as undecoded slices.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';

import '../helpers.dart';

void main() {
  test('sample: same content as jsonDecode, heavy fields lazy', () {
    final raw = sampleJson();
    final eager = parseContent(raw);
    final lazy = parseContentBytes(utf8.encode(raw));
    final doc = decodeContentLazily(utf8.encode(raw));
    final full = jsonDecode(raw) as Map<String, Object?>;

    expect(doc.keys, full.keys);
    for (final k in full.keys.where((k) => k != 'lessons')) {
      expect(doc[k], full[k], reason: k);
    }
    final lessons = doc['lessons']! as Map<String, Object?>;
    expect(lessons.keys, (full['lessons']! as Map).keys);
    for (final l in lessons.values.cast<Map<String, Object?>>()) {
      expect(l['sections'], isA<JsonSlice>());
    }

    expect(lazy.lessons.keys, eager.lessons.keys);
    for (final id in eager.lessons.keys) {
      final a = eager.lessons[id]!, b = lazy.lessons[id]!;
      expect(b.title, a.title);
      expect(b.diagramSvg, a.diagramSvg, reason: id);
      for (final lang in ContentLang.values) {
        final sa = a.sections(lang), sb = b.sections(lang);
        expect(sb.length, sa.length);
        for (var i = 0; i < sa.length; i++) {
          expect((sb[i].n, sb[i].heading, sb[i].md), (sa[i].n, sa[i].heading, sa[i].md));
        }
      }
    }
    expect(lazy.quizzes.keys, eager.quizzes.keys);
    expect(lazy.glossary.length, eager.glossary.length);
  });

  test('escapes, nesting and scalars around skipped values', () {
    const raw = r'''
 { "meta" : {"a": [1, -2.5e3, true, false, null, "x\"}]\\"]},
   "lessons": {"l1": {"id": "l1", "sections": {"vi": [{"n": 1, "heading": "Đơn \"}\" ]",
     "md": "a\\\"b é {[ "}], "en": []}, "diagram_svg": null, "n": 7}},
   "tail": "ok" }
''';
    final doc = decodeContentLazily(utf8.encode(raw));
    final full = jsonDecode(raw) as Map<String, Object?>;
    expect(doc['meta'], full['meta']);
    expect(doc['tail'], 'ok');
    final l1 = (doc['lessons']! as Map)['l1'] as Map;
    expect(l1['n'], 7);
    expect(
      (l1['sections'] as JsonSlice).decode(),
      ((full['lessons']! as Map)['l1'] as Map)['sections'],
    );
    expect((l1['diagram_svg'] as JsonSlice).decode(), isNull);
  });

  test('damaged documents fail like jsonDecode', () {
    for (final raw in [
      '{"meta": {}',
      '{"lessons": {"l": {"sections": "unterminated}}}',
      '{"a": 1} trailing',
      '{"a" 1}',
      '[]',
    ]) {
      expect(
        () => decodeContentLazily(utf8.encode(raw)),
        throwsFormatException,
        reason: raw,
      );
    }
  });

  test('a lazy section that does not decode reads as empty', () {
    final s = LessonSections.lazy(
      id: 'x',
      slice: JsonSlice(utf8.encode('{"vi": [}')),
    );
    expect(s.of(ContentLang.vi), isEmpty);
  });
}
