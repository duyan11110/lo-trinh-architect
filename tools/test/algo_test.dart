import 'package:test/test.dart';

import '../src/bloom.dart';
import '../src/code_source.dart';
import '../src/glossary.dart';
import '../src/headings.dart';
import '../src/markdown_util.dart';
import '../src/mermaid.dart';

void main() {
  group('A.1 word count', () {
    test('strips frontmatter-free body, code blocks, H2 lines, counts [[id]] and inline code as one word each', () {
      final body = '''
## Heading should not count

one two three [[some.id]] and `inline code span` and four.

```csharp
this code block
should not count at all
```

five.
''';
      // words: one two three X and X and four. five.  == 9
      expect(countWords(body), 9);
    });
  });

  group('A.2 term matching', () {
    final glossary = [
      GlossaryEntry(
          term: 'hash-map',
          en: 'hash map',
          viKeep: true,
          vi: 'hash map',
          shortVi: 'x',
          shortEn: 'x',
          introducedIn: 'x.l1.x',
          aliases: const []),
      GlossaryEntry(
          term: 'map',
          en: 'map',
          viKeep: true,
          vi: 'map',
          shortVi: 'x',
          shortEn: 'x',
          introducedIn: 'x.l1.x',
          aliases: const []),
      GlossaryEntry(
          term: 'dns',
          en: 'DNS',
          viKeep: true,
          vi: 'DNS',
          shortVi: 'x',
          shortEn: 'x',
          introducedIn: 'x.l1.x',
          aliases: const []),
      GlossaryEntry(
          term: 'commit',
          en: 'commit',
          viKeep: true,
          vi: 'commit',
          shortVi: 'x',
          shortEn: 'x',
          introducedIn: 'x.l1.x',
          aliases: const []),
    ];

    test('prefers the longest match at a position ("hash map" over "map")', () {
      final matches = findTermOccurrences('A hash map is fast.', glossary);
      expect(matches.map((m) => m.term), contains('hash-map'));
      expect(matches.map((m) => m.term), isNot(contains('map')));
    });

    test('an ALL-CAPS token only matches a glossary entry whose en is itself ALL-CAPS', () {
      final matches = findTermOccurrences('Run COMMIT now, then check DNS.', glossary);
      final terms = matches.map((m) => m.term).toList();
      expect(terms, contains('dns')); // DNS entry has en="DNS" (all caps) -> matches
      expect(terms, isNot(contains('commit'))); // commit entry's en is lowercase -> must not match COMMIT
    });

    test('skips fenced code, inline code and [[id]] links', () {
      final matches = findTermOccurrences('See `map` and [[map]] and\n```\nmap\n```\nbut not map here.', glossary);
      // Only the last, real prose "map" should match.
      expect(matches.length, 1);
    });

    test('simplePlural: y -> ies, s/x/z/ch/sh -> +es, else +s', () {
      expect(simplePlural('policy'), 'policies');
      expect(simplePlural('box'), 'boxes');
      expect(simplePlural('process'), 'processes');
      expect(simplePlural('branch'), 'branches');
      expect(simplePlural('term'), 'terms');
    });
  });

  group('A.3 heading normalization', () {
    test('trims, collapses whitespace, and treats "..." as "…", case-insensitively', () {
      expect(headingsMatch('  Beginners   often think...  ', 'Beginners often think…'), isTrue);
      expect(headingsMatch('BEGINNERS OFTEN THINK…', 'beginners often think…'), isTrue);
      expect(headingsMatch('Something else', 'Beginners often think…'), isFalse);
    });

    test('expectedHeadings: stage <=2 uses "Beginners…", stage >=3 uses "Seniors…"', () {
      expect(expectedHeadings('en', 1, 0)[5], 'Beginners often think…');
      expect(expectedHeadings('en', 1, 3)[5], 'Seniors often assume…');
      expect(expectedHeadings('vi', 1, 0)[5], 'Người mới hay nghĩ rằng…');
      expect(expectedHeadings('vi', 1, 4)[5], 'Senior hay nhầm rằng…');
    });

    test('level 4 has 11 sections with Trade-offs/What would you choose if…', () {
      final headings = expectedHeadings('en', 4, 3);
      expect(headings.length, 11);
      expect(headings[5], 'Trade-offs');
      expect(headings[6], 'What would you choose if…');
    });
  });

  group('A.4 Bloom rounding', () {
    test('acceptedCountRange: e=n*p/100, range [floor(e)-1, ceil(e)+1] clamped to [0,n]', () {
      final r = acceptedCountRange(6, 25); // e = 1.5 -> [0, 3]
      expect(r.min, 0);
      expect(r.max, 3);
      expect(r.contains(0), isTrue);
      expect(r.contains(3), isTrue);
      expect(r.contains(4), isFalse);
    });

    test('bloomBucket pools analyze and evaluate', () {
      expect(bloomBucket('analyze'), 'analyze_evaluate');
      expect(bloomBucket('evaluate'), 'analyze_evaluate');
      expect(bloomBucket('remember'), 'remember');
    });
  });

  group('A.5 mermaid node counting', () {
    test('sequenceDiagram counts distinct participants', () {
      final content = '''
sequenceDiagram
  participant C as Client
  participant S as Server
  C->>S: request
  S-->>C: response
''';
      expect(countNodes(content), 2);
    });

    test('flowchart counts unique node ids', () {
      final content = '''
flowchart LR
  A[Start] --> B[Middle]
  B --> C[End]
''';
      expect(countNodes(content), 3);
    });

    test('flowchart node count over 8 is detectable', () {
      final ids = List.generate(9, (i) => String.fromCharCode(65 + i));
      final lines = <String>['flowchart LR'];
      for (int i = 0; i < ids.length - 1; i++) {
        lines.add('  ${ids[i]} --> ${ids[i + 1]}');
      }
      expect(countNodes(lines.join('\n')), 9);
    });
  });

  group('A.6 output matching', () {
    test('"..." in the block matches any run of characters, non-greedy, across the whole file', () {
      const block = 'Date: ...\nContent-Length: 412\nBody: ...';
      const file = 'Date: Mon, 06 Sep 2026 10:00:00 GMT\nContent-Length: 412\nBody: <html>hi</html>';
      expect(matchOutputBlock(blockContent: block, fileContent: file), isTrue);
    });

    test('normalizes CRLF and trailing whitespace before matching', () {
      const block = 'line1\nline2';
      const file = 'line1   \r\nline2\r\n';
      expect(matchOutputBlock(blockContent: block, fileContent: file), isTrue);
    });

    test('rejects content that does not match', () {
      const block = 'Status: 200';
      const file = 'Status: 404';
      expect(matchOutputBlock(blockContent: block, fileContent: file), isFalse);
    });
  });

  group('A.7 code matching', () {
    test('with lines=a-b: exact match required, and block line count must equal b-a+1', () {
      const file = 'l1\nl2\nl3\nl4\nl5';
      final err = matchCodeBlock(blockContent: 'l2\nl3', fileContent: file, linesSpec: '2-3');
      expect(err, isNull);
    });

    test('with lines=a-b: mismatched line count is rejected', () {
      const file = 'l1\nl2\nl3\nl4\nl5';
      final err = matchCodeBlock(blockContent: 'l2', fileContent: file, linesSpec: '2-3');
      expect(err, isNotNull);
    });

    test('without lines=: block must be a contiguous run of lines in the file', () {
      const file = 'a\nb\nc\nd\ne';
      expect(matchCodeBlock(blockContent: 'b\nc\nd', fileContent: file), isNull);
      expect(matchCodeBlock(blockContent: 'b\nd', fileContent: file), isNotNull);
    });

    test('normalization: trailing whitespace and CRLF and tabs are ignored', () {
      const file = 'if (x) {\r\n\tdoStuff();   \r\n}';
      const block = 'if (x) {\n    doStuff();\n}';
      expect(matchCodeBlock(blockContent: block, fileContent: file), isNull);
    });
  });
}
