// M2 Done: S1 → S3 → read (docs/07 §11), and the S3 states of docs/05 S3.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/lesson_status.dart';
import 'package:lta_app/progress/progress_repository.dart';

import '../helpers.dart';

void main() {
  final content = sampleContent();
  final lesson = content.lessons.values.single;
  final module = content.module(lesson.moduleKey)!;
  final index = module.lessons.indexWhere((r) => r.id == lesson.id) + 1;
  final quizCount = content.quizzes[lesson.id]!.questions.length;

  late AppDatabase db;
  late ProgressRepository repo;

  setUp(() {
    db = memoryDb();
    repo = ProgressRepository(db, FixedClock(testEpoch));
  });
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpLesson(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: themedApp(LessonScreen(lessonId: lesson.id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollPosition readingScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      )
      .position;

  Future<void> scrollTo(WidgetTester tester, double ratio) async {
    final p = readingScroll(tester);
    p.jumpTo(ratio * p.maxScrollExtent);
    await tester.pumpAndSettle();
  }

  Future<LessonStatus?> status() async => (await repo.get(lesson.id))?.status;

  testWidgets('open → read → mark read: Học tiếp, scroll to summary', (
    tester,
  ) async {
    await pumpApp(tester);

    // S1, fresh install.
    expect(find.text('BẮT ĐẦU · GIAI ĐOẠN 0'), findsOneWidget);
    // Title on the card and in "Module hiện tại".
    expect(find.text(lesson.title.vi), findsNWidgets(2));
    expect(
      find.text('Bài $index/${module.lessons.length} trong module'),
      findsOneWidget,
    );
    expect(find.textContaining('bài tới cổng'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Học tiếp'));
    await tester.pumpAndSettle();

    // S3: opened, no action bar at the top.
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(await status(), LessonStatus.opened);
    expect(find.text('Đánh dấu đã đọc, quiz sau'), findsNothing);

    // Summary in view → read, vocab recorded.
    await scrollTo(tester, 1);
    expect(await status(), LessonStatus.read);
    final seen = await db.select(db.vocabSeen).get();
    expect({for (final v in seen) v.term}, lesson.vocab.toSet());
    expect(find.text('Làm quiz · $quizCount câu'), findsOneWidget);
    expect(find.text('Đánh dấu đã đọc, quiz sau'), findsNothing);

    // Back on S1: the only lesson with a body is read.
    // The action bar must leave the app bar tappable.
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có bài mới trong nội dung hiện tại'), findsOneWidget);
    expect(find.text('Module hiện tại'), findsOneWidget);
    expect(find.text('tùy chọn'), findsWidgets);
  });

  testWidgets('"Đánh dấu đã đọc, quiz sau" marks read before the summary', (
    tester,
  ) async {
    await pumpLesson(tester);
    await scrollTo(tester, 0.8);
    expect(await status(), LessonStatus.opened);
    final markRead = find.text('Đánh dấu đã đọc, quiz sau');
    expect(markRead, findsOneWidget);

    await tester.tap(markRead);
    await tester.pumpAndSettle();
    expect(await status(), LessonStatus.read);
    expect(markRead, findsNothing);
  });

  testWidgets('scroll position is restored on reopen', (tester) async {
    await repo.markOpened(lesson.id);
    await repo.saveScroll(lesson.id, 0.5);
    await pumpLesson(tester);
    final p = readingScroll(tester);
    expect(p.pixels / p.maxScrollExtent, closeTo(0.5, 0.01));
    expect(await status(), LessonStatus.opened);
  });

  testWidgets('read, quiz not passed: "Làm quiz" + last score', (
    tester,
  ) async {
    await repo.markRead(lesson.id);
    await db
        .into(db.quizAttempt)
        .insert(
          QuizAttemptCompanion.insert(
            kind: 'lesson',
            refId: lesson.id,
            startedAt: '2026-11-04T00:00:00.000Z',
            finishedAt: const Value('2026-11-04T00:05:00.000Z'),
            score: const Value(4),
            total: const Value(6),
            questionIds: '[]',
          ),
        );
    await pumpLesson(tester);
    await scrollTo(tester, 1);
    expect(find.text('Làm quiz · $quizCount câu'), findsOneWidget);
    expect(find.text('Lần trước: 4/6'), findsOneWidget);
    expect(find.text('Đánh dấu đã đọc, quiz sau'), findsNothing);
  });

  testWidgets('passed: "Làm lại quiz"; "đã cập nhật" when content grew', (
    tester,
  ) async {
    await repo.recordQuizScore(
      lesson.id,
      ratio: 1,
      contentVersion: lesson.contentVersion - 1,
    );
    await pumpLesson(tester);
    expect(find.text('ĐÃ CẬP NHẬT'), findsOneWidget);
    await scrollTo(tester, 1);
    expect(find.text('Làm lại quiz'), findsOneWidget);
    expect(await status(), LessonStatus.passed);
  });

  testWidgets('passed with the current content: no "đã cập nhật"', (
    tester,
  ) async {
    await repo.recordQuizScore(
      lesson.id,
      ratio: 1,
      contentVersion: lesson.contentVersion,
    );
    await pumpLesson(tester);
    expect(find.text('ĐÃ CẬP NHẬT'), findsNothing);
  });

  testWidgets('Aa sheet changes the reading size immediately', (tester) async {
    await pumpLesson(tester);
    await tester.tap(find.byTooltip('Cỡ chữ'));
    await tester.pumpAndSettle();
    expect(find.text('Khoảng dòng'), findsOneWidget);
    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    final segmented = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>).first,
    );
    expect(segmented.selected, {3});
  });
}
