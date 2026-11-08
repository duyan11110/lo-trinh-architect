// M5 S9 Tìm on the sample content: ≥ 2 characters, accented Vietnamese
// queries match (case folded), unaccented ones do not (docs/07 §4 keeps
// diacritics), English terms match, docs/05 §7 empty copy, filter chips,
// tap opens the lesson, `/search?q=` pre-fills.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/lesson/lesson_screen.dart';
import 'package:lta_app/features/search/search_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/database.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Content content;
  setUp(() {
    db = memoryDb();
    content = sampleContent();
  });
  tearDown(() => db.close());

  String lessonId() => content.lessons.keys.single;
  Finder hit() => find.byKey(ValueKey('search-hit-${lessonId()}'));

  Future<void> openSearch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tìm').last);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('search-field')), text);
    await tester.pumpAndSettle();
  }

  testWidgets('accented / unaccented / English / empty', (tester) async {
    await openSearch(tester);
    // One character: no search, no empty message.
    await type(tester, 'đ');
    expect(hit(), findsNothing);
    expect(find.textContaining('Không thấy'), findsNothing);

    await type(tester, 'đồng nghiệp');
    expect(hit(), findsOneWidget);
    // Track group header.
    expect(find.text(content.tracks.first.title.vi), findsWidgets);
    expect(find.textContaining('GĐ0 · Chưa học'), findsOneWidget);

    await type(tester, 'ĐỒNG NGHIỆP');
    expect(hit(), findsOneWidget);

    await type(tester, 'đồng ng');
    expect(hit(), findsOneWidget);

    await type(tester, 'dong nghiep');
    expect(hit(), findsNothing);
    expect(
      find.text(
        'Không thấy "dong nghiep". Thử từ tiếng Anh — thuật ngữ trong bài giữ tiếng Anh.',
      ),
      findsOneWidget,
    );

    await type(tester, 'response');
    expect(hit(), findsOneWidget);
  });

  testWidgets('filters: "Chưa học", stage', (tester) async {
    await openSearch(tester);
    await type(tester, 'response');
    expect(hit(), findsOneWidget);
    final stage = content.lessons.values.single.stage;
    final other = content.stages.map((s) => s.stage).firstWhere((s) => s != stage);
    await tester.tap(find.widgetWithText(FilterChip, 'GĐ$other'));
    await tester.pumpAndSettle();
    expect(hit(), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'GĐ$stage'));
    await tester.pumpAndSettle();
    expect(hit(), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Chưa học'));
    await tester.pumpAndSettle();
    expect(hit(), findsOneWidget);
  });

  testWidgets('tap opens the lesson', (tester) async {
    await openSearch(tester);
    await type(tester, 'response');
    await tester.tap(hit());
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(
      tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId,
      lessonId(),
    );
  });

  testWidgets('?q= pre-fills and searches', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db)],
        child: themedApp(const SearchScreen(initialQuery: 'response')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('response'), findsWidgets);
    expect(hit(), findsOneWidget);
  });
}
