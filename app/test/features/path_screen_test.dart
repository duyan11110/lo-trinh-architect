// M4: S2 Lộ trình (stages + "Theo track"), StageBar on S1 → /path?stage=n,
// S5 prereq dialog before S3 (docs/05 S1, S2, S5).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lta_app/app/locations.dart';
import 'package:lta_app/app/router.dart';
import 'package:lta_app/features/lesson/prereq_dialog.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/lesson_status.dart';
import 'package:lta_app/progress/progress_repository.dart';
import 'package:lta_app/shared/stage_bar.dart';

import '../fixtures/content_builder.dart';
import '../helpers.dart';

void main() {
  const a = BModule('foundation', 'a', 0, [
    BLesson('a1'),
    BLesson('a2'),
    BLesson('a-side', main: false),
  ]);
  const b = BModule('foundation', 'b', 0, [
    BLesson('b1', available: false),
    BLesson(
      'b2',
      prereqs: ['foundation.l1.a1', 'foundation.l1.a2'],
    ),
  ]);
  const c = BModule('backend', 'c', 1, [BLesson('c1')]);
  final content = buildContent([a, b, c]);
  String id(BModule m, String slug) => '${m.track}.l1.$slug';

  late AppDatabase db;
  late ProgressRepository repo;
  setUp(() {
    db = memoryDb();
    repo = ProgressRepository(db, FixedClock(testEpoch));
  });
  tearDown(() => db.close());

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...builtContentOverrides(content), ...progressOverrides(db)],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(LtaApp)),
    ).read(routerProvider);
  }

  String location(GoRouter r) {
    final config = r.routerDelegate.currentConfiguration;
    final last = config.last;
    return (last is ImperativeRouteMatch ? last.matches : config).uri
        .toString();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  testWidgets('S2: current stage open, module of "Học tiếp" open, sắp có', (
    tester,
  ) async {
    await repo.recordQuizScore(id(a, 'a1'), ratio: 1, contentVersion: 1);
    final router = await pumpApp(tester);
    router.go(pathLocation());
    await tester.pumpAndSettle();

    expect(find.text('GIAI ĐOẠN 0 · STAGE 0'), findsOneWidget);
    expect(find.text('GIAI ĐOẠN 1 · STAGE 1'), findsOneWidget);
    expect(find.text('Cổng: chưa thi'), findsNWidgets(2));
    // Stage 0: 1 of 4 main-path lessons passed; module a: 1/3 (side too).
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    // Module a holds "Học tiếp" (a2) → open; module b closed; stage 1 closed.
    expect(find.text(id(a, 'a2')), findsOneWidget);
    expect(find.text('tùy chọn'), findsOneWidget);
    expect(find.text(id(b, 'b2')), findsNothing);
    expect(find.text('c'), findsNothing);

    await tap(tester, find.text('b'));
    expect(find.text(id(b, 'b1')), findsOneWidget);
    expect(find.text('sắp có'), findsOneWidget);
    // "sắp có" rows do not open.
    await tap(tester, find.text(id(b, 'b1')));
    expect(location(router), pathLocation());

    // Collapse module a; the state survives leaving the tab.
    await tap(tester, find.text('a'));
    expect(find.text(id(a, 'a2')), findsNothing);
    router.go(homeLocation);
    await tester.pumpAndSettle();
    router.go(pathLocation());
    await tester.pumpAndSettle();
    expect(find.text(id(a, 'a2')), findsNothing);

    // A lesson row opens S3.
    await tap(tester, find.text('a'));
    await tap(tester, find.text(id(a, 'a2')));
    expect(location(router), lessonLocation(id(a, 'a2')));
  });

  testWidgets('S1 StageBar → /path?stage=n opens that stage', (tester) async {
    final router = await pumpApp(tester);
    expect(find.byType(StageBar), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Giai đoạn 1'));
    expect(location(router), pathLocation(stage: 1));
    expect(find.text('c'), findsOneWidget);
    expect(find.text('GIAI ĐOẠN 1 · STAGE 1'), findsOneWidget);
  });

  testWidgets('"Theo track": track → L1 → module → lesson with stage tag', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.go(pathLocation());
    await tester.pumpAndSettle();
    await tap(tester, find.text('Theo track'));
    expect(location(router), pathTracksLocation);
    expect(find.text('foundation'), findsOneWidget);
    expect(find.text('backend'), findsOneWidget);

    await tap(tester, find.text('backend'));
    expect(find.text('L1 · L1'), findsWidgets);
    await tap(tester, find.text('c'));
    expect(find.text(id(c, 'c1')), findsOneWidget);
    expect(find.text('GĐ1'), findsOneWidget);

    await tap(tester, find.text('Giai đoạn').last);
    expect(location(router), pathLocation());
  });

  group('S5', () {
    testWidgets('"Cứ đọc" reads; shown once per lesson', (tester) async {
      await repo.recordQuizScore(id(a, 'a2'), ratio: 1, contentVersion: 1);
      final router = await pumpApp(tester);
      router.push(lessonLocation(id(b, 'b2')));
      await tester.pumpAndSettle();

      expect(find.byType(PrereqDialog), findsOneWidget);
      expect(
        find.text('Bài này dựa trên 1 bài bạn chưa qua quiz'),
        findsOneWidget,
      );
      expect(find.text(id(a, 'a1')), findsOneWidget);
      expect(find.text(id(a, 'a2')), findsNothing); // passed
      // Not opened while the dialog is up.
      expect((await repo.get(id(b, 'b2')))?.status, LessonStatus.newLesson);

      await tap(tester, find.text('Cứ đọc'));
      expect(find.byType(PrereqDialog), findsNothing);
      final r = await repo.get(id(b, 'b2'));
      expect(r!.prereqWarned, isTrue);
      // Opened (a one-section stub is read at once).
      expect(r.status.atLeast(LessonStatus.opened), isTrue);

      router.pop();
      await tester.pumpAndSettle();
      router.push(lessonLocation(id(b, 'b2')));
      await tester.pumpAndSettle();
      expect(find.byType(PrereqDialog), findsNothing);
    });

    testWidgets('"Học bài trước" opens the first missing prereq, queues the '
        'lesson', (tester) async {
      final router = await pumpApp(tester);
      router.push(lessonLocation(id(b, 'b2')));
      await tester.pumpAndSettle();
      expect(
        find.text('Bài này dựa trên 2 bài bạn chưa qua quiz'),
        findsOneWidget,
      );
      await tap(tester, find.text('Học bài trước'));
      expect(location(router), lessonLocation(id(a, 'a1')));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LtaApp)),
      );
      expect(container.read(prereqReturnProvider), id(b, 'b2'));
      expect(
        (await repo.get(id(a, 'a1')))!.status.atLeast(LessonStatus.opened),
        isTrue,
      );
      expect((await repo.get(id(b, 'b2')))?.status, LessonStatus.newLesson);
    });

    testWidgets('tapping a prereq row opens that lesson', (tester) async {
      final router = await pumpApp(tester);
      router.push(lessonLocation(id(b, 'b2')));
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.descendant(
          of: find.byType(PrereqDialog),
          matching: find.text(id(a, 'a2')),
        ),
      );
      expect(location(router), lessonLocation(id(a, 'a2')));
    });
  });
}
