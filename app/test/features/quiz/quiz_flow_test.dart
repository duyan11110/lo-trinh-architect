// S4/S6 behaviour around the questions: S3 opens S4, leaving asks first,
// an app kill resumes, "Đọc lại mục N", and the S6 states (docs/05 S4, S6,
// §10).
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lta_app/app/router.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';
import 'package:lta_app/features/quiz/quiz_screen.dart';
import 'package:lta_app/features/quiz/result_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/lesson_status.dart';

import '../../flows/everyday_flow.dart' show answerQuestion;
import '../../helpers.dart';

void main() {
  final content = sampleContent();
  final lesson = content.lessons.values.single;
  final quiz = content.quizzes[lesson.id]!;
  final n = quiz.questions.length;

  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<GoRouter> pumpApp(WidgetTester tester) async {
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

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  Future<void> answerAndCheck(WidgetTester tester, Question q, {bool wrong = false}) async {
    await answerQuestion(tester, q, wrong: wrong);
    await tapText(tester, 'Kiểm tra');
  }

  testWidgets('S3 "Làm quiz" opens S4 at question 1', (tester) async {
    final router = await pumpApp(tester);
    router.push(lessonLocation(lesson.id));
    await tester.pumpAndSettle();
    final p = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(LessonScreen),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    ).position;
    p.jumpTo(p.maxScrollExtent);
    await tester.pumpAndSettle();
    await tapText(tester, 'Làm quiz · $n câu');
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('Câu 1/$n'), findsOneWidget);
    // Eyebrow: bloom · section.
    final q = quiz.questions.first;
    expect(find.textContaining('MỤC ${q.sectionRef}'), findsOneWidget);
  });

  testWidgets('✕ with no answer leaves at once', (tester) async {
    final router = await pumpApp(tester);
    router.push(quizLocation(lesson.id));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thoát quiz'));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('✕ after an answer asks; "Ở lại" stays, "Thoát" abandons', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.push(quizLocation(lesson.id));
    await tester.pumpAndSettle();
    await answerAndCheck(tester, quiz.questions.first, wrong: true);

    await tester.tap(find.byTooltip('Thoát quiz'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Thoát quiz? Câu đã trả lời được lưu vào ôn tập; điểm không được tính.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Ở lại');
    expect(find.byType(QuizScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Thoát quiz'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Thoát');
    expect(find.byType(QuizScreen), findsNothing);
    final attempt = (await db.select(db.quizAttempt).get()).single;
    expect(attempt.finishedAt, isNotNull);
    expect(attempt.score, isNull);
    expect(await db.select(db.reviewItem).get(), hasLength(1));
    // No score → status unchanged.
    final row = await db.select(db.lessonProgress).get();
    expect(row, isEmpty);
  });

  testWidgets('app killed mid-quiz: reopening resumes at the next question', (
    tester,
  ) async {
    final ids = [for (final q in quiz.questions) q.id];
    final id = await db
        .into(db.quizAttempt)
        .insert(
          QuizAttemptCompanion.insert(
            kind: 'lesson',
            refId: lesson.id,
            startedAt: '2026-11-05T07:00:00.000Z',
            questionIds: '["${ids.join('","')}"]',
          ),
        );
    await db
        .into(db.quizAnswer)
        .insert(
          QuizAnswerCompanion.insert(
            attemptId: id,
            questionId: ids.first,
            answer: '["x"]',
            correct: 1,
            answeredAt: '2026-11-05T07:01:00.000Z',
          ),
        );
    final router = await pumpApp(tester);
    router.push(quizLocation(lesson.id));
    await tester.pumpAndSettle();
    expect(find.text('Câu 2/$n'), findsOneWidget);
    expect(await db.select(db.quizAttempt).get(), hasLength(1));
  });

  testWidgets('"Đọc lại mục N" opens the lesson at #sN; back returns', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.push(quizLocation(lesson.id));
    await tester.pumpAndSettle();
    final q = quiz.questions.first;
    await answerAndCheck(tester, q);
    await tapText(tester, 'Đọc lại mục ${q.sectionRef}');
    final screen = tester.widget<LessonScreen>(find.byType(LessonScreen));
    expect(screen.initialSection, q.sectionRef);
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Câu 1/$n'), findsOneWidget);
    expect(find.text('Tiếp'), findsOneWidget);
  });

  testWidgets('all right: "Không có câu sai.", skills, back to Học tiếp', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.push(quizLocation(lesson.id));
    await tester.pumpAndSettle();
    for (final q in quiz.questions) {
      await answerAndCheck(tester, q);
      await tapText(tester, 'Tiếp');
    }
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('$n/$n · Đã qua'), findsOneWidget);
    expect(find.text('Không có câu sai.'), findsOneWidget);
    expect(find.text('Kỹ năng'), findsOneWidget);
    expect(find.byType(SkillDelta), findsNWidgets(lesson.skills.length));
    expect(await db.select(db.reviewItem).get(), isEmpty);
    final row = (await db.select(db.lessonProgress).get()).single;
    expect(row.status, LessonStatus.passed.db);
    expect(row.bestScore, 1);
    expect(row.contentVersion, lesson.contentVersion);
  });

  testWidgets('not passed: recap, "Đọc lại bài" + "Làm lại quiz"', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.push(lessonLocation(lesson.id));
    await tester.pumpAndSettle();
    router.push(quizLocation(lesson.id));
    await tester.pumpAndSettle();
    // Wrong on the first three: 3/6 = 50%.
    for (final (i, q) in quiz.questions.indexed) {
      await answerAndCheck(tester, q, wrong: i < 3);
      await tapText(tester, 'Tiếp');
    }
    expect(find.text('${n - 3}/$n · Chưa qua (cần ≥ 70%)'), findsOneWidget);
    expect(find.byType(QuestionRecap), findsNWidgets(3));
    expect(
      find.text('Những câu này sẽ xuất hiện trong Ôn tập vào ngày mai.'),
      findsOneWidget,
    );
    expect(find.text('Kỹ năng'), findsNothing);
    expect(await db.select(db.reviewItem).get(), hasLength(3));

    await tapText(tester, 'Làm lại quiz');
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('Câu 1/$n'), findsOneWidget);
    // Fresh attempt.
    expect(await db.select(db.quizAttempt).get(), hasLength(2));
    await tester.tap(find.byTooltip('Thoát quiz'));
    await tester.pumpAndSettle();

    // The lesson below shows "Lần trước: 3/6".
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('result for an unknown attempt says so', (tester) async {
    final router = await pumpApp(tester);
    router.push(resultLocation(lesson.id, 999));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy lần làm quiz này.'), findsOneWidget);
  });

  testWidgets('deep link to a result rebuilds Học tiếp → bài → kết quả', (
    tester,
  ) async {
    final id = await db
        .into(db.quizAttempt)
        .insert(
          QuizAttemptCompanion.insert(
            kind: 'lesson',
            refId: lesson.id,
            startedAt: '2026-11-05T07:00:00.000Z',
            finishedAt: const Value('2026-11-05T07:05:00.000Z'),
            score: const Value(6),
            total: const Value(6),
            questionIds: '[]',
          ),
        );
    final router = await pumpApp(tester);
    router.go(resultLocation(lesson.id, id));
    await tester.pumpAndSettle();
    expect(find.text('6/6 · Đã qua'), findsOneWidget);
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  });
}
