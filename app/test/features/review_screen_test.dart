// M5: S7 Ôn tập (empty, due, session with tier lines and summary), the
// S1 ReviewDueRow, the vocabulary tab and TermTooltip "Thêm vào ôn". Real
// router, sample content, in-memory database, fixed clock (DECISIONS.md E7).
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/review/review_session_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/quiz_repository.dart';
import 'package:lta_app/progress/review_repository.dart';

import '../../integration_test/flows/everyday_flow.dart';
import '../helpers.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late Content content;
  setUp(() {
    db = memoryDb();
    clock = FixedClock(testEpoch);
    content = sampleContent();
  });
  tearDown(() => db.close());

  Question q(int i) => content.quizzes.values.single.questions[i];
  String lessonId() => content.lessons.keys.single;

  Future<void> wrong(String id) async {
    final quiz = QuizRepository(db, clock);
    final a = await quiz.startOrResume(QuizKind.lesson, lessonId(), [id]);
    await quiz.recordAnswer(
      attemptId: a.id,
      kind: QuizKind.lesson,
      questionId: id,
      answer: const ['x'],
      correct: false,
      sourceLesson: lessonId(),
    );
    await quiz.finish(a.id, score: 0, total: 1);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...contentOverrides(),
          ...progressOverrides(db, clock: clock),
          reviewRandomProvider.overrideWithValue(Random(1)),
        ],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openReview(WidgetTester tester) async {
    await tester.tap(find.text('Ôn tập').last);
    await tester.pumpAndSettle();
  }

  testWidgets('empty: docs/05 copy + "Học tiếp"', (tester) async {
    await pumpApp(tester);
    await openReview(tester);
    expect(
      find.text('Chưa có gì để ôn. Câu bạn trả lời sai sẽ xuất hiện ở đây sau 1 ngày.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Học tiếp'), findsOneWidget);
    // Nothing due → S1 has no ReviewDueRow.
    await tester.tap(find.widgetWithText(FilledButton, 'Học tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('Ôn hôm nay'), findsNothing);
  });

  testWidgets('wrong today → "Sắp tới · Ngày mai 1", history', (tester) async {
    await wrong(q(0).id);
    await pumpApp(tester);
    await openReview(tester);
    expect(find.text('Sắp tới'), findsOneWidget);
    expect(find.text('Ngày mai 1'), findsOneWidget);
    expect(find.text('Đến hạn hôm nay'), findsNothing);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
  });

  testWidgets('due tomorrow: S7 session → tier line → summary → Học tiếp', (
    tester,
  ) async {
    await wrong(q(0).id);
    clock.advance(const Duration(days: 1));
    await pumpApp(tester);

    // S1 ReviewDueRow.
    expect(find.text('Ôn hôm nay'), findsOneWidget);
    expect(find.text('1 câu'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ôn 1 phút'), findsOneWidget);

    await openReview(tester);
    expect(find.text('Đến hạn hôm nay'), findsOneWidget);
    expect(find.text('1 bài · ~1 phút'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu ôn'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSessionScreen), findsOneWidget);
    expect(find.text('Câu 1/1'), findsOneWidget);
    expect(find.textContaining('ÔN · '), findsOneWidget);
    await answerQuestion(tester, q(0));
    await tester.tap(find.widgetWithText(FilledButton, 'Kiểm tra'));
    await tester.pumpAndSettle();
    expect(find.text('Đúng'), findsOneWidget);
    expect(find.text('Bậc 0 → 1 · gặp lại sau 3 ngày'), findsOneWidget);

    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('1/1 · 0 câu về bậc 0'), findsOneWidget);
    final item = (await db.select(db.reviewItem).get()).single;
    expect(item.tier, 1);
    expect(item.timesSeen, 1);
    final attempts = await db.select(db.quizAttempt).get();
    expect(attempts.last.kind, 'review');
    expect(attempts.last.score, 1);

    await tester.tap(find.text('Về Học tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('Ôn hôm nay'), findsNothing);
  });

  testWidgets('S1 "Ôn N phút" opens the session; wrong → "Về bậc 0"', (
    tester,
  ) async {
    await wrong(q(0).id);
    clock.advance(const Duration(days: 1));
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Ôn 1 phút'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewSessionScreen), findsOneWidget);
    await answerQuestion(tester, q(0), wrong: true);
    await tester.tap(find.widgetWithText(FilledButton, 'Kiểm tra'));
    await tester.pumpAndSettle();
    expect(find.text('Về bậc 0 · gặp lại ngày mai'), findsOneWidget);
  });

  testWidgets('vocabulary: grouped list, quick filter, "Thêm vào ôn"', (
    tester,
  ) async {
    await db.into(db.vocabSeen).insert(
      VocabSeenCompanion.insert(
        term: const Value('header'),
        firstLessonId: lessonId(),
        seenAt: isoUtc(testEpoch),
      ),
    );
    await db.into(db.vocabSeen).insert(
      VocabSeenCompanion.insert(
        term: const Value('status-code'),
        firstLessonId: lessonId(),
        seenAt: isoUtc(testEpoch),
      ),
    );
    await pumpApp(tester);
    await openReview(tester);
    await tester.tap(find.text('Từ vựng'));
    await tester.pumpAndSettle();

    final track = content.tracks.first.title.vi;
    expect(find.text(track), findsWidgets);
    expect(find.byKey(const ValueKey('vocab-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('vocab-status-code')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mã trạng');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vocab-header')), findsNothing);
    expect(find.byKey(const ValueKey('vocab-status-code')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Không thấy "zzz".'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('vocab-header')));
    await tester.pumpAndSettle();
    expect(find.text('Thêm vào ôn'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('term-add-review')));
    await tester.pumpAndSettle();
    expect(find.text('Đã thêm vào ôn'), findsOneWidget);
    final item = (await db.select(db.reviewItem).get()).single;
    expect(item.itemId, 'term:header');
    expect(item.kind, 'term');
    expect(DateTime.parse(item.dueAt), testEpoch.add(const Duration(days: 1)));

    // Reopening says it is already there.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('vocab-header')));
    await tester.pumpAndSettle();
    expect(find.text('Đã có trong ôn tập'), findsOneWidget);
  });

  testWidgets('term flashcard in a session: "<term> nghĩa là gì?"', (
    tester,
  ) async {
    await ReviewRepository(db, clock).addTerm(content.glossaryEntry('header')!);
    clock.advance(const Duration(days: 1));
    await pumpApp(tester);
    await openReview(tester);
    await tester.tap(find.text('Bắt đầu ôn'));
    await tester.pumpAndSettle();
    expect(find.text('header nghĩa là gì?'), findsOneWidget);
    final entry = content.glossaryEntry('header')!;
    await tester.tap(find.textContaining(entry.shortVi));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Kiểm tra'));
    await tester.pumpAndSettle();
    expect(find.text('Đúng'), findsOneWidget);
    expect(find.text('Bậc 0 → 1 · gặp lại sau 3 ngày'), findsOneWidget);
  });
}
