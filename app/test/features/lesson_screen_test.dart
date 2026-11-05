// M1 Done: S3 reads the sample lesson in VI and EN, light and dark.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/markdown/prose.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';

import '../helpers.dart';

void main() {
  final content = sampleContent();
  final lesson = content.lessons.values.first;

  Future<void> pump(
    WidgetTester tester, {
    required String id,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('vi'),
  }) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: themedApp(
          LessonScreen(lessonId: id),
          brightness: brightness,
          locale: locale,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('reads the sample in VI then EN (${brightness.name})', (
      tester,
    ) async {
      await pump(tester, id: lesson.id, brightness: brightness);

      expect(find.text(lesson.title.vi), findsOneWidget);
      expect(find.text(lesson.sectionsVi.first.heading), findsOneWidget);
      expect(find.byType(Prose), findsNWidgets(lesson.sectionsVi.length));

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.title.en), findsOneWidget);
      expect(find.text(lesson.title.vi), findsNothing);
      expect(find.text(lesson.sectionsEn.first.heading), findsOneWidget);
      // UI chrome stays in the app locale; content follows the toggle.
      expect(find.textContaining('sắp có'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('EN app locale defaults content to EN', (tester) async {
    await pump(tester, id: lesson.id, locale: const Locale('en'));
    expect(find.text(lesson.title.en), findsOneWidget);
    final module = content.module(lesson.moduleKey)!;
    final index = module.lessons.indexWhere((r) => r.id == lesson.id) + 1;
    expect(
      find.text(
        '${module.title.en} · Lesson $index/${module.lessons.length}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('unknown lesson id shows a message, no crash', (tester) async {
    await pump(tester, id: 'nope.l1.missing');
    expect(find.text('Không có bài này trong nội dung hiện tại.'), findsOneWidget);
  });
}
