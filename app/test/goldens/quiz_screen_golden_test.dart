// docs/07 §9 Golden: S4 `scenario` after "Kiểm tra" (wrong pick), light and
// dark. First goldens of M3 (DECISIONS.md E4). Question built in Dart (E6).
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/quiz/quiz_screen.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

void main() {
  final content = contentWithQuiz([
    buildQuestion('backend.l1.quiz-lesson.q1', QuestionType.scenario),
  ]);
  final lessonId = content.lessons.keys.single;

  goldenTest(
    'S4 scenario after check',
    fileName: 's4_scenario_checked',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      for (final b in Brightness.values) {
        final scenario = find.byKey(ValueKey('s4-${b.name}'));
        await tester.tap(
          find.descendant(of: scenario, matching: find.byKey(const ValueKey('option-a'))),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: scenario, matching: find.widgetWithText(FilledButton, 'Kiểm tra')),
        );
        await tester.pumpAndSettle();
      }
    },
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final b in Brightness.values)
          GoldenTestScenario(
            name: b.name,
            child: SizedBox(
              key: ValueKey('s4-${b.name}'),
              width: 390,
              height: 844,
              child: ProviderScope(
                overrides: [
                  ...builtContentOverrides(content),
                  ...progressOverrides(memoryDb()),
                ],
                child: themedApp(QuizScreen(lessonId: lessonId), brightness: b),
              ),
            ),
          ),
      ],
    ),
  );
}
