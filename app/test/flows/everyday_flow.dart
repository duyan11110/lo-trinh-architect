// docs/07 §9 "Luồng ngày thường": mở app → Học tiếp → đọc tới cuối → quiz
// (1 câu sai) → kết quả → (next day) Ôn hôm nay có 1 câu. Shared by
// the widget-level test (test/features/everyday_flow_test.dart, in-memory
// database) and the integration test (integration_test/, platform database,
// `-d chrome` on CI). Web-safe: no dart:io / drift native imports here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/content_repository.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/home/home_screen.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';
import 'package:lta_app/features/quiz/quiz_screen.dart';
import 'package:lta_app/features/quiz/result_screen.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/lesson_status.dart';
import 'package:lta_app/progress/review_repository.dart';

/// What the flow did, for extra assertions by the caller.
class EverydayFlowResult {
  EverydayFlowResult(this.lessonId, this.wrongQuestionId, this.total);
  final String lessonId;
  final String wrongQuestionId;
  final int total;
}

/// Pumps until [finder] matches (real async I/O in integration tests needs
/// more than one frame), failing after [tries] × 100 ms.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int tries = 100,
}) async {
  for (var i = 0; i < tries; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Answers [q] with its key, or with a wrong option when [wrong].
Future<void> answerQuestion(
  WidgetTester tester,
  Question q, {
  bool wrong = false,
}) async {
  switch (q.type) {
    case QuestionType.single:
    case QuestionType.truefalse:
    case QuestionType.scenario:
      final id = wrong
          ? q.options.firstWhere((o) => !q.answer.contains(o.id)).id
          : q.answer.first;
      await _tap(tester, find.byKey(ValueKey('option-$id')));
    case QuestionType.multi:
      final ids = wrong ? [q.answer.first] : q.answer;
      for (final id in ids) {
        await _tap(tester, find.byKey(ValueKey('option-$id')));
      }
    case QuestionType.order:
      final current = [for (final o in q.options) o.id];
      final target = wrong ? current.reversed.toList() : q.answer;
      for (var p = 0; p < target.length; p++) {
        final id = target[p];
        for (var j = current.indexOf(id); j > p; j--) {
          await _tap(tester, find.byKey(ValueKey('order-up-$id')));
          current
            ..remove(id)
            ..insert(j - 1, id);
        }
      }
    case QuestionType.fill:
      final field = find.descendant(
        of: find.byKey(ValueKey('fill-${q.id}')),
        matching: find.byType(TextField),
      );
      await pumpUntilFound(tester, field);
      await tester.enterText(field, wrong ? 'zzz' : q.answer.first);
      await tester.pumpAndSettle();
  }
}

Future<EverydayFlowResult> runEverydayFlow(
  WidgetTester tester,
  AppDatabase db,
) async {
  // S1 → S3.
  await _tap(tester, find.widgetWithText(FilledButton, 'Học tiếp'));
  await pumpUntilFound(tester, find.byType(LessonScreen));
  final lessonId = tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId;
  final content = ProviderScope.containerOf(
    tester.element(find.byType(LessonScreen)),
  ).read(contentProvider).requireValue;
  final quiz = content.quizzes[lessonId]!;
  final n = quiz.questions.length;

  // Read to the end: Summary in view → read; the action bar appears.
  final scrollable = find
      .descendant(
        of: find.byType(LessonScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      )
      .first;
  await pumpUntilFound(tester, scrollable);
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Làm quiz · $n câu'));

  // S4: every question right except the first `single` (or the first one).
  await pumpUntilFound(tester, find.byType(QuizScreen));
  final firstSingle = quiz.questions.indexWhere(
    (q) => q.type == QuestionType.single,
  );
  final wrongIndex = firstSingle < 0 ? 0 : firstSingle;
  for (final (i, q) in quiz.questions.indexed) {
    await pumpUntilFound(tester, find.text('Câu ${i + 1}/$n'));
    await answerQuestion(tester, q, wrong: i == wrongIndex);
    await _tap(tester, find.widgetWithText(FilledButton, 'Kiểm tra'));
    expect(
      i == wrongIndex
          ? find.textContaining('Chưa đúng — đáp án:')
          : find.text('Đúng'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Tiếp'));
  }

  // S6.
  await pumpUntilFound(tester, find.byType(ResultScreen));
  await pumpUntilFound(tester, find.text('${n - 1}/$n · Đã qua'));
  expect(find.text('Câu sai'), findsOneWidget);
  expect(find.byType(QuestionRecap), findsOneWidget);
  expect(
    find.text('Câu này sẽ xuất hiện trong Ôn tập vào ngày mai.'),
    findsOneWidget,
  );

  final wrongId = quiz.questions[wrongIndex].id;
  final items = await db.select(db.reviewItem).get();
  expect([for (final r in items) r.itemId], [wrongId]);
  expect(items.single.tier, 0);
  expect(items.single.sourceLesson, lessonId);
  final progress = await (db.select(
    db.lessonProgress,
  )..where((t) => t.lessonId.equals(lessonId))).getSingle();
  expect(progress.status, LessonStatus.passed.db);

  // Back to Học tiếp.
  await _tap(tester, find.text('Về Học tiếp'));
  await pumpUntilFound(tester, find.byType(HomeScreen));
  expect(find.byType(ResultScreen), findsNothing);
  return EverydayFlowResult(lessonId, wrongId, n);
}

/// docs/07 §9 last step: "Ôn hôm nay có 1 câu sau khi đổi giờ hệ thống" —
/// the next review day (clock + 1 day, app back in the foreground) S1 shows
/// the ReviewDueRow with the one wrong question.
Future<void> runReviewNextDay(WidgetTester tester, FixedClock clock) async {
  expect(find.text('Ôn hôm nay'), findsNothing);
  clock.advance(const Duration(days: 1));
  ProviderScope.containerOf(tester.element(find.byType(HomeScreen)))
      .read(reviewDayProvider.notifier)
      .refresh();
  await pumpUntilFound(tester, find.text('Ôn hôm nay'));
  expect(find.text('1 câu'), findsOneWidget);
}
