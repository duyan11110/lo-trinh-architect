// docs/07 §9 Widget: `Prose` renders the sample lesson with the right number
// of CodeBlock / OutputBlock / DiagramView / TermSpan / LessonLinkChip
// (including "sắp có" chips). Grammar not present in the sample (details,
// table, available link) is covered by a fixture built in Dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/glossary_matcher.dart';
import 'package:lta_app/content/markdown/blocks.dart';
import 'package:lta_app/content/markdown/grammar.dart';
import 'package:lta_app/content/markdown/prose.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/shared/code_block.dart';
import 'package:lta_app/shared/diagram_view.dart';
import 'package:lta_app/shared/lesson_link_chip.dart';
import 'package:lta_app/shared/prose_cards.dart';

import '../helpers.dart';

/// Counts derived from the block model, independent of the widgets.
class _Expected {
  int code = 0, output = 0, diagram = 0, terms = 0;
  final links = <String>[];

  void inlines(List<Inline> xs) {
    for (final r in xs) {
      if (r is TextRun && r.term != null) terms++;
      if (r is LinkRun) links.add(r.lessonId);
    }
  }

  void blocks(List<ProseBlock> bs) {
    for (final b in bs) {
      switch (b) {
        case ParagraphBlock(:final inlines):
          this.inlines(inlines);
        case CodeBlockData():
          code++;
        case OutputBlockData():
          output++;
        case DiagramBlock():
          diagram++;
        case ListBlock(:final items):
          for (final i in items) {
            switch (i) {
              case PlainItem(:final blocks):
                this.blocks(blocks);
              case MisconceptionItem(:final belief, :final truth):
                inlines(belief);
                inlines(truth);
              case LinkItem(:final lessonId, :final relation):
                links.add(lessonId);
                inlines(relation);
            }
          }
        case ExpectedBlock(:final blocks):
          this.blocks(blocks);
        case DetailsBlock(:final blocks):
          this.blocks(blocks);
        case TableBlock(:final header, :final rows):
          header.forEach(inlines);
          for (final r in rows) {
            r.forEach(inlines);
          }
        case UnsupportedBlock():
          break;
      }
    }
  }
}

int _countTermSpans(WidgetTester tester) {
  var n = 0;
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    rt.text.visitChildren((span) {
      if (span is TermTextSpan) n++;
      return true;
    });
  }
  return n;
}

ProseLinks _links(Content c, ContentLang lang) => ProseLinks(
  titleOf: (id) => c.lessonTitle(id)?.of(lang),
  isAvailable: c.lessons.containsKey,
);

Widget _lesson(Content c, Lesson lesson, ContentLang lang) {
  final parser = ProseParser(
    matcher: GlossaryMatcher(c.glossary, lang: lang),
  );
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          for (final s in lesson.sections(lang))
            Prose(
              blocks: parser.parse(s.md),
              lang: lang,
              links: _links(c, lang),
              role: SectionRole.of(level: lesson.level, n: s.n),
              lessonId: lesson.id,
              diagramSvg: lesson.diagramSvg,
            ),
        ],
      ),
    ),
  );
}

void main() {
  final content = sampleContent();

  for (final lesson in content.lessons.values) {
    for (final lang in ContentLang.values) {
      testWidgets('sample ${lesson.id} (${lang.name}) renders every block', (
        tester,
      ) async {
        final exp = _Expected();
        final parser = ProseParser(
          matcher: GlossaryMatcher(content.glossary, lang: lang),
        );
        for (final s in lesson.sections(lang)) {
          exp.blocks(parser.parse(s.md));
        }
        // The sample exercises these; guard against a silently empty parse.
        expect(exp.code, greaterThan(0));
        expect(exp.output, greaterThan(0));
        expect(exp.diagram, 1);
        expect(exp.terms, greaterThan(0));
        expect(exp.links, isNotEmpty);

        await tester.pumpWidget(themedApp(_lesson(content, lesson, lang)));
        await tester.pumpAndSettle();

        expect(find.byType(CodeBlock), findsNWidgets(exp.code));
        expect(find.byType(OutputBlock), findsNWidgets(exp.output));
        expect(find.byType(DiagramView), findsNWidgets(exp.diagram));
        expect(_countTermSpans(tester), exp.terms);

        final chips = tester.widgetList<LessonLinkChip>(
          find.byType(LessonLinkChip),
        );
        expect(chips.length, exp.links.length);
        final upcoming = exp.links
            .where((id) => !content.lessons.containsKey(id))
            .length;
        expect(chips.where((c) => c.upcoming).length, upcoming);
        expect(find.textContaining('sắp có'), findsNWidgets(upcoming));

        expect(find.byType(MisconceptionCard), findsWidgets);
        expect(find.byType(TryItPanel), findsOneWidget);
        expect(find.byType(SummaryBox), findsOneWidget);
        expect(
          find.text(lang == ContentLang.vi ? 'Kết quả mong đợi' : 'Expected result'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Dart fixture: available link, details, table, missing diagram', (
    tester,
  ) async {
    final lesson = content.lessons.values.first;
    final parser = ProseParser(
      matcher: GlossaryMatcher(content.glossary, lang: ContentLang.en),
    );
    final blocks = parser.parse(
      'Back to [[${lesson.id}]].\n\n'
      '{{diagram}}\n\n'
      '| Option | Cost |\n|---|---|\n| A | low |\n| B | high |\n\n'
      '<details><summary>Suggested answer</summary>\n\n'
      'A **header** line.\n\n'
      '</details>\n\n'
      '#### Not in the grammar',
    );
    await tester.pumpWidget(
      themedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Prose(
              blocks: blocks,
              lang: ContentLang.en,
              links: _links(content, ContentLang.en),
              lessonId: lesson.id,
            ),
          ),
        ),
        locale: const Locale('en'),
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    final chip = tester.widget<LessonLinkChip>(find.byType(LessonLinkChip));
    expect(chip.upcoming, isFalse);
    expect(chip.title, lesson.title.en);
    expect(find.text('Diagram not rendered'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text('Not in the grammar'), findsOneWidget);

    // Details body is parsed as Markdown and revealed on tap.
    await tester.tap(find.text('Suggested answer'));
    await tester.pumpAndSettle();
    expect(_countTermSpans(tester), greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a term opens the TermTooltip', (tester) async {
    final parser = ProseParser(
      matcher: GlossaryMatcher(content.glossary, lang: ContentLang.vi),
    );
    final entry = content.glossary.first;
    await tester.pumpWidget(
      themedApp(
        Scaffold(
          body: Prose(
            blocks: parser.parse('**${entry.en}**'),
            lang: ContentLang.vi,
            links: _links(content, ContentLang.vi),
          ),
        ),
      ),
    );
    await tester.tapOnText(find.textRange.ofSubstring(entry.en));
    await tester.pumpAndSettle();
    expect(find.text(entry.shortVi), findsOneWidget);
    expect(find.text('Học ở:'), findsOneWidget);
  });
}
