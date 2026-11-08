// docs/07 §9 Unit `markdown/grammar`: fence info (3 keys, missing key,
// output=true), [[id]] inline, {{diagram}}, misconception split at → ,
// Expected result, <details>; plus tables and unsupported syntax.
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/glossary_matcher.dart';
import 'package:lta_app/content/markdown/blocks.dart';
import 'package:lta_app/content/markdown/grammar.dart';
import 'package:lta_app/content/models/models.dart';

const _header = GlossaryEntry(
  term: 'header',
  en: 'header',
  viKeep: true,
  vi: 'header',
  shortVi: 'Một dòng mô tả',
  shortEn: 'One metadata line',
  introducedIn: 'foundation.l1.http-request-response',
);

ProseParser _parser([ContentLang lang = ContentLang.en]) =>
    ProseParser(matcher: GlossaryMatcher(const [_header], lang: lang));

String _text(List<Inline> xs) => xs
    .map(
      (r) => switch (r) {
        TextRun(:final text) => text,
        CodeRun(:final text) => '`$text`',
        LinkRun(:final lessonId) => '[[$lessonId]]',
        BreakRun() => '\n',
      },
    )
    .join();

void main() {
  group('parseFenceInfo', () {
    test('lang + file + tag + lines', () {
      final f = parseFenceInfo(
        'bash file=scripts/http/raw-request.sh tag=stage-0 lines=1-6',
      );
      expect(f.lang, 'bash');
      expect(f.file, 'scripts/http/raw-request.sh');
      expect(f.tag, 'stage-0');
      expect((f.lineStart, f.lineEnd), (1, 6));
      expect(f.isSourceRef, isTrue);
      expect(f.output, isFalse);
    });

    test('lines is optional', () {
      final f = parseFenceInfo('csharp file=src/Api/Program.cs tag=stage-1');
      expect(f.isSourceRef, isTrue);
      expect(f.lineStart, isNull);
    });

    test('missing tag → not a source ref', () {
      final f = parseFenceInfo('bash file=scripts/up.sh');
      expect(f.isSourceRef, isFalse);
      expect(f.lang, 'bash');
      expect(f.file, isNull, reason: 'rendered without header chips');
    });

    test('keys out of order or malformed lines → not a source ref', () {
      expect(parseFenceInfo('bash tag=stage-0 file=a.sh').isSourceRef, isFalse);
      expect(
        parseFenceInfo('bash file=a.sh tag=stage-0 lines=x').isSourceRef,
        isFalse,
      );
      expect(parseFenceInfo('bash').isSourceRef, isFalse);
    });

    test('text output=true', () {
      expect(parseFenceInfo('text output=true').output, isTrue);
      expect(parseFenceInfo('bash output=true').output, isFalse);
    });
  });

  group('ProseParser', () {
    test('fences become CodeBlockData / OutputBlockData', () {
      final blocks = _parser().parse(
        '```bash file=a.sh tag=stage-0 lines=2-3\necho hi\nls\n```\n\n'
        '```text output=true\nhi\n```\n\n'
        '```yaml\nk: v\n```',
      );
      expect(blocks, hasLength(3));
      final code = blocks[0] as CodeBlockData;
      expect(code.code, 'echo hi\nls');
      expect(code.info.file, 'a.sh');
      expect((blocks[1] as OutputBlockData).text, 'hi');
      expect((blocks[2] as CodeBlockData).info.isSourceRef, isFalse);
    });

    test('[[id]] inline and not inside code', () {
      final p = _parser().parse(
        'See [[foundation.l1.http-methods]] and `[[not.a.link]]`.',
      );
      final inl = (p.single as ParagraphBlock).inlines;
      expect(
        inl.whereType<LinkRun>().single.lessonId,
        'foundation.l1.http-methods',
      );
      expect(inl.whereType<CodeRun>().single.text, '[[not.a.link]]');
    });

    test('line {{diagram}} → DiagramBlock; inline mention stays text', () {
      final p = _parser().parse('{{diagram}}\n\nText {{diagram}} here.');
      expect(p.first, isA<DiagramBlock>());
      expect(p[1], isA<ParagraphBlock>());
    });

    test('misconception bullet splits at the first →', () {
      final p = _parser().parse(
        '- **"A response always has a body."** → Actually not → ever.\n'
        '- **"No arrow here."** just text',
      );
      final items = (p.single as ListBlock).items;
      final m = items[0] as MisconceptionItem;
      expect(_text(m.belief), '"A response always has a body."');
      expect(_text(m.truth), 'Actually not → ever.');
      expect(items[1], isA<PlainItem>());
    });

    test('link bullet [[id]] — relation', () {
      final p = _parser().parse(
        '- [[backend.l1.request-lifecycle]] — the same request, from the server.\n'
        '- [[a.b]] no dash',
      );
      final items = (p.single as ListBlock).items;
      final link = items[0] as LinkItem;
      expect(link.lessonId, 'backend.l1.request-lifecycle');
      expect(_text(link.relation), 'the same request, from the server.');
      expect(items[1], isA<PlainItem>());
    });

    test('Expected result: to end of section, stopping at <details>', () {
      final p = _parser().parse(
        '1. Run it.\n\n'
        'Expected result: the first line is `HTTP/1.1 200 OK`.\n\n'
        'Second line of the expectation.\n\n'
        '<details><summary>Suggested answer</summary>\n\n'
        'Because **header** lines end at the blank line.\n\n'
        '</details>',
      );
      expect(p.map((b) => b.runtimeType), [
        ListBlock,
        ExpectedBlock,
        DetailsBlock,
      ]);
      final e = p[1] as ExpectedBlock;
      expect(e.label, 'Expected result');
      expect(e.blocks, hasLength(2));
      expect(
        _text((e.blocks.first as ParagraphBlock).inlines),
        'the first line is `HTTP/1.1 200 OK`.',
      );
      final d = p[2] as DetailsBlock;
      expect(d.summary, 'Suggested answer');
      final inner = (d.blocks.single as ParagraphBlock).inlines;
      expect(
        inner.whereType<TextRun>().where((r) => r.term != null),
        isNotEmpty,
      );
    });

    test('Kết quả mong đợi: (vi)', () {
      final p = _parser(ContentLang.vi).parse('Kết quả mong đợi: ba dòng.');
      final e = p.single as ExpectedBlock;
      expect(e.label, 'Kết quả mong đợi');
      expect(_text((e.blocks.single as ParagraphBlock).inlines), 'ba dòng.');
    });

    test('<details> on a single line is parsed again as Markdown', () {
      final p = _parser().parse(
        '<details><summary>Hint</summary>Use `nc`.</details>',
      );
      final d = p.single as DetailsBlock;
      expect(d.summary, 'Hint');
      final inl = (d.blocks.single as ParagraphBlock).inlines;
      expect(inl.whereType<CodeRun>().single.text, 'nc');
    });

    test('GFM table', () {
      final p = _parser().parse(
        '| A | B |\n|---|---|\n| 1 | `x` |\n| 2 | y |',
      );
      final t = p.single as TableBlock;
      expect(t.header, hasLength(2));
      expect(t.rows, hasLength(2));
      expect(t.rows.first[1].single, isA<CodeRun>());
    });

    test('bold term → TermSpan; other bold stays bold', () {
      final p = _parser().parse('**header** (one line) and **not a term**.');
      final runs = (p.single as ParagraphBlock).inlines.whereType<TextRun>();
      expect(runs.first.term?.term, 'header');
      expect(runs.first.bold, isTrue);
      expect(runs.firstWhere((r) => r.text == 'not a term').term, isNull);
    });

    test('unsupported syntax renders as text, never throws', () {
      final p = _parser().parse(
        '### Heading\n\n'
        'A [link](https://example.com) and ![img](x.png).\n\n'
        '> quote\n\n'
        '<div>raw</div>\n\n'
        '---\n\n'
        '~~strike~~',
      );
      final all = p
          .map(
            (b) => switch (b) {
              ParagraphBlock(:final inlines) => _text(inlines),
              UnsupportedBlock(:final text) => text,
              _ => '',
            },
          )
          .join('|');
      for (final s in ['Heading', 'link', 'img', 'quote', '<div>raw</div>', 'strike']) {
        expect(all, contains(s));
      }
    });
  });
}
