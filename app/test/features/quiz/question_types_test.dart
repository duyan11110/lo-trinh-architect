// docs/07 §9 Widget: 6 question types × (idle, selected, correct, wrong);
// `truefalse` groups by `polarity`; `order` shows the JSON order. Questions
// are built in Dart (DECISIONS.md E6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/quiz/question_widgets/quiz_option.dart';
import 'package:lta_app/features/quiz/quiz_screen.dart';
import 'package:lta_app/progress/database.dart';

import '../../fixtures/content_builder.dart';
import '../../../integration_test/flows/everyday_flow.dart' show answerQuestion;
import '../../helpers.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<Content> pumpQuiz(WidgetTester tester, Question q) async {
    final content = contentWithQuiz([q]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...builtContentOverrides(content), ...progressOverrides(db)],
        child: themedApp(QuizScreen(lessonId: content.lessons.keys.single)),
      ),
    );
    await tester.pumpAndSettle();
    return content;
  }

  QuizOptionState state(WidgetTester tester, String id) =>
      tester.widget<QuizOption>(find.byKey(ValueKey('option-$id'))).state;

  FilledButton checkButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Kiểm tra'));

  Future<void> check(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Kiểm tra'));
    await tester.pumpAndSettle();
  }

  Future<List<ReviewItemData>> reviewItems() => db.select(db.reviewItem).get();

  double dy(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

  /// The four states for the option-based types.
  void optionTypeTests(
    QuestionType type, {
    required List<String> correctPick,
    required List<String> wrongPick,
    required String answerText,
  }) {
    final q = buildQuestion('backend.l1.quiz-lesson.q1', type);

    testWidgets('${type.name}: idle', (tester) async {
      await pumpQuiz(tester, q);
      expect(find.text('Câu 1/1'), findsOneWidget);
      expect(checkButton(tester).onPressed, isNull);
      for (final o in q.options) {
        expect(state(tester, o.id), QuizOptionState.idle);
      }
    });

    testWidgets('${type.name}: selected', (tester) async {
      await pumpQuiz(tester, q);
      await tester.tap(find.byKey(ValueKey('option-${wrongPick.first}')));
      await tester.pumpAndSettle();
      expect(state(tester, wrongPick.first), QuizOptionState.selected);
      expect(checkButton(tester).onPressed, isNotNull);
      final option = tester.widget<QuizOption>(
        find.byKey(ValueKey('option-${wrongPick.first}')),
      );
      expect(option.chosen, isTrue);
      expect(
        option.kind,
        type == QuestionType.multi ? QuizOptionKind.checkbox : QuizOptionKind.radio,
      );
    });

    testWidgets('${type.name}: correct', (tester) async {
      await pumpQuiz(tester, q);
      for (final id in correctPick) {
        await tester.tap(find.byKey(ValueKey('option-$id')));
        await tester.pumpAndSettle();
      }
      await check(tester);
      expect(find.text('Đúng'), findsOneWidget);
      for (final o in q.options) {
        expect(
          state(tester, o.id),
          q.answer.contains(o.id) ? QuizOptionState.correct : QuizOptionState.dimmed,
        );
      }
      expect(find.text('BẠN CHỌN'), findsNothing);
      expect(find.text('Tiếp'), findsOneWidget);
      expect(find.text('Đọc lại mục 4'), findsOneWidget);
      expect(await reviewItems(), isEmpty);
      final answer = (await db.select(db.quizAnswer).get()).single;
      expect(answer.correct, 1);
    });

    testWidgets('${type.name}: wrong', (tester) async {
      await pumpQuiz(tester, q);
      for (final id in wrongPick) {
        await tester.tap(find.byKey(ValueKey('option-$id')));
        await tester.pumpAndSettle();
      }
      await check(tester);
      expect(find.text('Chưa đúng — đáp án: $answerText'), findsOneWidget);
      for (final id in wrongPick.where((id) => !q.answer.contains(id))) {
        expect(state(tester, id), QuizOptionState.wrong);
        expect(find.text('Vì sao ${id.toUpperCase()} không đúng'), findsOneWidget);
      }
      for (final id in q.answer) {
        expect(state(tester, id), QuizOptionState.correct);
      }
      expect(find.text('BẠN CHỌN'), findsNWidgets(wrongPick.length));
      final items = await reviewItems();
      expect(items.single.itemId, q.id);
      expect(items.single.tier, 0);
      expect(DateTime.parse(items.single.dueAt), testEpoch.add(const Duration(days: 1)));
    });
  }

  optionTypeTests(
    QuestionType.single,
    correctPick: ['b'],
    wrongPick: ['a'],
    answerText: 'B',
  );
  optionTypeTests(
    QuestionType.multi,
    correctPick: ['a', 'c'],
    wrongPick: ['a', 'b'],
    answerText: 'A, C',
  );
  optionTypeTests(
    QuestionType.scenario,
    correctPick: ['b'],
    wrongPick: ['a'],
    answerText: 'B',
  );

  group('multi', () {
    testWidgets('says "Chọn tất cả ý đúng"; a subset is wrong', (tester) async {
      final q = buildQuestion('backend.l1.quiz-lesson.q1', QuestionType.multi);
      await pumpQuiz(tester, q);
      expect(find.text('Chọn tất cả ý đúng'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('option-a')));
      await tester.pumpAndSettle();
      await check(tester);
      expect(find.text('Chưa đúng — đáp án: A, C'), findsOneWidget);
      // The missed right answer still shows ✓.
      expect(state(tester, 'c'), QuizOptionState.correct);
    });
  });

  group('scenario', () {
    testWidgets('ContextCard open by default, collapses; "Khi nào … lại đúng"', (
      tester,
    ) async {
      final q = buildQuestion('backend.l1.quiz-lesson.q1', QuestionType.scenario);
      await pumpQuiz(tester, q);
      expect(find.text('TÌNH HUỐNG'), findsOneWidget);
      expect(find.text('Context: a team of three ships a shop'), findsOneWidget);
      await tester.tap(find.text('TÌNH HUỐNG'));
      await tester.pumpAndSettle();
      expect(find.text('Context: a team of three ships a shop'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('option-a')));
      await tester.pumpAndSettle();
      await check(tester);
      expect(find.text('Vì sao A không đúng'), findsOneWidget);
      expect(find.text('Khi nào phương án C lại đúng'), findsOneWidget);
      expect(find.text('Khi nào phương án D lại đúng'), findsOneWidget);
    });
  });

  group('truefalse (by polarity)', () {
    // Polarity deliberately not in a,b = true order: the rows follow it.
    final q = buildQuestion(
      'backend.l1.quiz-lesson.q1',
      QuestionType.truefalse,
      polarity: const [false, false, true, true],
      answer: const ['c'],
    );

    testWidgets('idle: rows "Đúng, vì…" then "Sai, vì…" from polarity', (
      tester,
    ) async {
      await pumpQuiz(tester, q);
      final trueRow = find.byKey(const ValueKey('tf-true'));
      final falseRow = find.byKey(const ValueKey('tf-false'));
      expect(tester.widget<Text>(trueRow).data, 'Đúng, vì…');
      expect(tester.widget<Text>(falseRow).data, 'Sai, vì…');
      final c = find.byKey(const ValueKey('option-c'));
      final d = find.byKey(const ValueKey('option-d'));
      final a = find.byKey(const ValueKey('option-a'));
      final b = find.byKey(const ValueKey('option-b'));
      expect(dy(tester, trueRow), lessThan(dy(tester, c)));
      expect(dy(tester, c), lessThan(dy(tester, d)));
      expect(dy(tester, d), lessThan(dy(tester, falseRow)));
      expect(dy(tester, falseRow), lessThan(dy(tester, a)));
      expect(dy(tester, a), lessThan(dy(tester, b)));
      expect(checkButton(tester).onPressed, isNull);
    });

    testWidgets('selected', (tester) async {
      await pumpQuiz(tester, q);
      await tester.tap(find.byKey(const ValueKey('option-d')));
      await tester.pumpAndSettle();
      expect(state(tester, 'd'), QuizOptionState.selected);
      expect(checkButton(tester).onPressed, isNotNull);
    });

    testWidgets('correct', (tester) async {
      await pumpQuiz(tester, q);
      await tester.tap(find.byKey(const ValueKey('option-c')));
      await tester.pumpAndSettle();
      await check(tester);
      expect(find.text('Đúng'), findsOneWidget);
      expect(state(tester, 'c'), QuizOptionState.correct);
      expect(state(tester, 'a'), QuizOptionState.dimmed);
    });

    testWidgets('wrong', (tester) async {
      await pumpQuiz(tester, q);
      await tester.tap(find.byKey(const ValueKey('option-a')));
      await tester.pumpAndSettle();
      await check(tester);
      expect(find.text('Chưa đúng — đáp án: C'), findsOneWidget);
      expect(state(tester, 'a'), QuizOptionState.wrong);
      expect(state(tester, 'c'), QuizOptionState.correct);
      expect((await reviewItems()).single.itemId, q.id);
    });

    testWidgets('no polarity field: falls back to the "True, because" prefix', (
      tester,
    ) async {
      final sample = sampleContent();
      final tf = sample.quizzes.values
          .expand((z) => z.questions)
          .firstWhere((q) => q.type == QuestionType.truefalse);
      expect(tf.options.every((o) => o.polarity == null), isTrue);
      await pumpQuiz(tester, tf);
      final trueRow = find.byKey(const ValueKey('tf-true'));
      final falseRow = find.byKey(const ValueKey('tf-false'));
      expect(trueRow, findsOneWidget);
      expect(falseRow, findsOneWidget);
      // The row label replaces the "Đúng, vì" prefix on the cards.
      expect(find.textContaining('Đúng, vì client'), findsNothing);
    });
  });

  group('order', () {
    final q = buildQuestion('backend.l1.quiz-lesson.q1', QuestionType.order);
    List<double> rows(WidgetTester tester) => [
      for (final o in q.options)
        dy(tester, find.byKey(ValueKey('order-${o.id}'))),
    ];

    testWidgets('idle: steps in JSON order', (tester) async {
      await pumpQuiz(tester, q);
      final y = rows(tester);
      for (var i = 1; i < y.length; i++) {
        expect(y[i - 1], lessThan(y[i]));
      }
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(4));
      expect(find.byTooltip('Lên'), findsNWidgets(4));
    });

    testWidgets('selected: ▲ moves a step up and renumbers', (tester) async {
      await pumpQuiz(tester, q);
      await tester.tap(find.byKey(const ValueKey('order-up-b')));
      await tester.pumpAndSettle();
      expect(
        dy(tester, find.byKey(const ValueKey('order-b'))),
        lessThan(dy(tester, find.byKey(const ValueKey('order-a')))),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('order-b')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('correct', (tester) async {
      await pumpQuiz(tester, q);
      await answerQuestion(tester, q);
      await check(tester);
      expect(find.text('Đúng'), findsOneWidget);
      expect(find.text('BẠN XẾP'), findsNothing);
      final answer = (await db.select(db.quizAnswer).get()).single;
      expect(answer.answer, '["d","c","b","a"]');
    });

    testWidgets('wrong: "Bạn xếp" next to "Đúng"', (tester) async {
      await pumpQuiz(tester, q);
      await check(tester);
      expect(find.text('Chưa đúng — đáp án: D → C → B → A'), findsOneWidget);
      expect(find.text('BẠN XẾP'), findsOneWidget);
      expect(find.text('ĐÚNG'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('order-yours-a'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('order-answer-a'))).dx),
      );
      expect((await reviewItems()).single.itemId, q.id);
    });
  });

  group('fill', () {
    final q = buildQuestion(
      'backend.l1.quiz-lesson.q1',
      QuestionType.fill,
      answer: const ['Skip'],
      answerRegex: r'^\.?[Ss]kip$',
    );
    Finder field() => find.descendant(
      of: find.byKey(ValueKey('fill-${q.id}')),
      matching: find.byType(TextField),
    );

    testWidgets('idle: inline mono field, no autocorrect', (tester) async {
      await pumpQuiz(tester, q);
      final tf = tester.widget<TextField>(field());
      expect(tf.autocorrect, isFalse);
      expect(tf.enableSuggestions, isFalse);
      expect(tf.style!.fontFamily, 'JetBrainsMono');
      expect(checkButton(tester).onPressed, isNull);
    });

    testWidgets('selected: typing enables "Kiểm tra"', (tester) async {
      await pumpQuiz(tester, q);
      await tester.enterText(field(), 'Take');
      await tester.pumpAndSettle();
      expect(checkButton(tester).onPressed, isNotNull);
    });

    testWidgets('correct: trimmed, case-insensitive', (tester) async {
      await pumpQuiz(tester, q);
      await tester.enterText(field(), '  SKIP ');
      await tester.pumpAndSettle();
      await check(tester);
      expect(find.text('Đúng'), findsOneWidget);
      expect(tester.widget<TextField>(field()).readOnly, isTrue);
    });

    testWidgets('wrong: shows the accepted answers', (tester) async {
      await pumpQuiz(tester, q);
      await tester.enterText(field(), 'Take');
      await tester.pumpAndSettle();
      await check(tester);
      expect(find.text('Chưa đúng — đáp án: Skip'), findsOneWidget);
      expect(find.text('Đáp án chấp nhận: Skip'), findsOneWidget);
      expect((await reviewItems()).single.itemId, q.id);
    });
  });

  testWidgets('VI → EN mid-question keeps the choice by option id', (
    tester,
  ) async {
    final q = buildQuestion('backend.l1.quiz-lesson.q1', QuestionType.single);
    await pumpQuiz(tester, q);
    await tester.tap(find.byKey(const ValueKey('option-c')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(state(tester, 'c'), QuizOptionState.selected);
  });
}
