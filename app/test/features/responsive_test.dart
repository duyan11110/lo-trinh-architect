// M7 (docs/05 §9, §2, S2/S3/S4 Web): nav rail from 900 dp, S3 three
// zones + keys, S2 two columns, S4 keys, TermTooltip popover.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lta_app/app/router.dart';
import 'package:lta_app/content/markdown/prose.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';
import 'package:lta_app/features/quiz/explanation_panel.dart';
import 'package:lta_app/features/quiz/quiz_screen.dart';
import 'package:lta_app/features/search/search_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/database.dart';

import '../helpers.dart';

void main() {
  final content = sampleContent();
  final lesson = content.lessons.values.single;

  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<GoRouter> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(LtaApp)),
    ).read(routerProvider);
  }

  Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
    await tester.sendKeyEvent(k);
    await tester.pumpAndSettle();
  }

  testWidgets('shell: bottom nav below 900, rail from 900', (tester) async {
    await pumpApp(tester, const Size(899, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Ôn tập'));
    await tester.pumpAndSettle();
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 2);
  });

  testWidgets('S3 ≥ 1100: contents, 72 ch column, meta card', (tester) async {
    final router = await pumpApp(tester, const Size(1280, 900));
    router.push('/learn/${lesson.id}');
    await tester.pumpAndSettle();

    expect(find.text('MỤC LỤC'), findsOneWidget);
    for (final s in lesson.sectionsVi) {
      expect(find.byKey(ValueKey('toc-${s.n}')), findsOneWidget);
    }
    expect(find.text('THỜI LƯỢNG'), findsOneWidget);
    expect(find.text('LIÊN HỆ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 900–1099: no meta column.
    tester.view.physicalSize = const Size(1000, 900);
    await tester.pumpAndSettle();
    expect(find.text('MỤC LỤC'), findsOneWidget);
    expect(find.text('THỜI LƯỢNG'), findsNothing);

    // Phone: one column.
    tester.view.physicalSize = const Size(400, 900);
    await tester.pumpAndSettle();
    expect(find.text('MỤC LỤC'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('S3 keys: j/k sections, l language, q quiz', (tester) async {
    final router = await pumpApp(tester, const Size(1280, 900));
    router.push('/learn/${lesson.id}');
    await tester.pumpAndSettle();

    FontWeight? weight(int n) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey('toc-$n')),
          matching: find.byType(Text),
        ),
      );
      return text.style?.fontWeight;
    }

    final first = lesson.sectionsVi.first.n;
    final second = lesson.sectionsVi[1].n;
    expect(weight(first), FontWeight.w700);
    await key(tester, LogicalKeyboardKey.keyJ);
    expect(weight(second), FontWeight.w700);
    expect(weight(first), isNot(FontWeight.w700));
    await key(tester, LogicalKeyboardKey.keyK);
    expect(weight(first), FontWeight.w700);

    await key(tester, LogicalKeyboardKey.keyL);
    expect(find.text(lesson.title.en), findsOneWidget);

    await key(tester, LogicalKeyboardKey.keyQ);
    expect(find.byType(QuizScreen), findsOneWidget);
  });

  testWidgets('S3 "/" opens Tìm', (tester) async {
    final router = await pumpApp(tester, const Size(1280, 900));
    router.push('/learn/${lesson.id}');
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.slash);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('S3 ≥ 900: tapping a term opens a popover', (tester) async {
    final router = await pumpApp(tester, const Size(1280, 900));
    router.push('/learn/${lesson.id}');
    await tester.pumpAndSettle();
    final entry = content.glossary.firstWhere(
      (e) => e.term == lesson.vocab.first,
    );
    final span = find.textRange.ofSubstring(entry.en);
    await tester.ensureVisible(find.byType(Prose).at(2));
    await tester.pumpAndSettle();
    await tester.tapOnText(span.first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('term-popover')), findsOneWidget);
    expect(find.text(entry.shortVi), findsOneWidget);

    await key(tester, LogicalKeyboardKey.escape);
    expect(find.byKey(const ValueKey('term-popover')), findsNothing);
  });

  testWidgets('S4 keys: Enter checks / moves on, 1–6 choose', (tester) async {
    final router = await pumpApp(tester, const Size(1280, 900));
    router.push('/learn/${lesson.id}/quiz');
    await tester.pumpAndSettle();
    final quiz = content.quizzes[lesson.id]!;
    final n = quiz.questions.length;
    expect(find.text('Câu 1/$n'), findsOneWidget);

    // q1 `order` starts complete: Enter checks, Enter moves on.
    await key(tester, LogicalKeyboardKey.enter);
    expect(find.byType(ExplanationPanel), findsOneWidget);
    await key(tester, LogicalKeyboardKey.enter);
    expect(find.text('Câu 2/$n'), findsOneWidget);
    expect(find.byType(ExplanationPanel), findsNothing);

    // q2: choose the answer by its number, then Enter.
    final q2 = quiz.questions[1];
    final index = q2.options.indexWhere((o) => o.id == q2.answer.single);
    await key(tester, LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index));
    await key(tester, LogicalKeyboardKey.enter);
    expect(find.text('Đúng'), findsOneWidget);
  });

  testWidgets('S2 ≥ 900: modules on the left, lessons on the right', (
    tester,
  ) async {
    final router = await pumpApp(tester, const Size(1280, 900));
    router.go('/path');
    await tester.pumpAndSettle();
    final module = content.module(lesson.moduleKey)!;
    // The module of "Học tiếp" is shown on the right.
    expect(find.text(module.title.vi), findsWidgets);
    for (final r in module.lessons) {
      expect(find.text(r.title.vi), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
