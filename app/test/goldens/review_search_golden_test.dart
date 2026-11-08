// M5 first goldens (DECISIONS.md E4): S7 Ôn tập "Hôm nay" with due items,
// "Sắp tới" and history; S9 Tìm with a highlighted result. Light and dark,
// sample content (E6), seeded in-memory databases, fixed clock (E7).
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/features/review/review_screen.dart';
import 'package:lta_app/features/search/search_screen.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/quiz_repository.dart';
import 'package:lta_app/progress/review_repository.dart';

import '../helpers.dart';

Future<AppDatabase> _seededReviewDb() async {
  final db = memoryDb();
  final content = sampleContent();
  final lessonId = content.lessons.keys.single;
  final questions = content.quizzes.values.single.questions;
  final yesterday = FixedClock(testEpoch.subtract(const Duration(days: 1)));
  final quiz = QuizRepository(db, yesterday);
  final a = await quiz.startOrResume(
    QuizKind.lesson,
    lessonId,
    [for (final q in questions) q.id],
  );
  for (final (i, q) in questions.indexed) {
    await quiz.recordAnswer(
      attemptId: a.id,
      kind: QuizKind.lesson,
      questionId: q.id,
      answer: const ['x'],
      correct: i >= 2,
      sourceLesson: lessonId,
    );
  }
  await quiz.finish(a.id, score: questions.length - 2, total: questions.length);
  await ReviewRepository(db, FixedClock(testEpoch))
      .addTerm(content.glossaryEntry('header')!);
  return db;
}

void main() {
  final reviewDbs = <Brightness, AppDatabase>{};
  setUpAll(() async {
    for (final b in Brightness.values) {
      reviewDbs[b] = await _seededReviewDb();
    }
  });

  goldenTest(
    'S7 review today',
    fileName: 's7_review',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final b in Brightness.values)
          GoldenTestScenario(
            name: b.name,
            child: SizedBox(
              width: 390,
              height: 844,
              child: ProviderScope(
                overrides: [
                  ...contentOverrides(),
                  ...progressOverrides(reviewDbs[b]!),
                ],
                child: themedApp(const ReviewScreen(), brightness: b),
              ),
            ),
          ),
      ],
    ),
  );

  goldenTest(
    'S9 search results',
    fileName: 's9_search',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final b in Brightness.values)
          GoldenTestScenario(
            name: b.name,
            child: SizedBox(
              width: 390,
              height: 844,
              child: ProviderScope(
                overrides: [
                  ...contentOverrides(),
                  ...progressOverrides(memoryDb()),
                ],
                child: themedApp(
                  const SearchScreen(initialQuery: 'response'),
                  brightness: b,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
