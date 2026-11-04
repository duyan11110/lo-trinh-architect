// docs/07 §9 Golden: S3 with the sample lesson, light/dark × font step 0/2.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lta_app/content/content_repository.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';

import '../helpers.dart';

class _FixedPrefs extends ReadingPrefsNotifier {
  _FixedPrefs(this.step);
  final int step;
  @override
  ReadingPrefs build() => ReadingPrefs(fontStep: step);
}

void main() {
  final lessonId = sampleContent().lessons.keys.first;

  goldenTest(
    'S3 lesson screen',
    fileName: 's3_lesson',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final b in Brightness.values)
          for (final step in const [0, 2])
            GoldenTestScenario(
              name: '${b.name} · font step $step',
              child: SizedBox(
                width: 390,
                height: 1400,
                child: ProviderScope(
                  overrides: [
                    ...contentOverrides(),
                    ...progressOverrides(memoryDb()),
                    readingPrefsProvider.overrideWith(() => _FixedPrefs(step)),
                  ],
                  child: themedApp(
                    LessonScreen(lessonId: lessonId),
                    brightness: b,
                  ),
                ),
              ),
            ),
      ],
    ),
  );
}
