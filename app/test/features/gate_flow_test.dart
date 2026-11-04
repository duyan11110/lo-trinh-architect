// M6 S8 + gate exam + gate result + S1 failed-gate card, the module quiz
// from S2 ("Module ✓"), S1 "Tiếp tục quiz", and S10 persistence / export /
// import — widget level on built content (DECISIONS.md E6) with an
// in-memory database and fixed clock.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/content_repository.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/gate/gate_exam_screen.dart';
import 'package:lta_app/features/gate/gate_intro_screen.dart';
import 'package:lta_app/features/gate/gate_result_screen.dart';
import 'package:lta_app/features/home/home_screen.dart';
import 'package:lta_app/features/quiz/module_quiz_screen.dart';
import 'package:lta_app/features/settings/progress_files.dart';
import 'package:lta_app/features/settings/settings_screen.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';
import 'package:lta_app/progress/exam_repository.dart';
import 'package:lta_app/progress/progress_repository.dart';
import 'package:lta_app/progress/quiz_repository.dart';
import 'package:lta_app/progress/settings_repository.dart';

import '../fixtures/content_builder.dart';
import '../flows/everyday_flow.dart' show pumpUntilFound;
import '../helpers.dart';

class _Files implements ProgressFiles {
  String? saved;
  String? toPick;

  @override
  Future<String?> pick() async => toPick;

  @override
  Future<void> save(String name, String json) async => saved = json;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late FixedClock clock;
  final content = contentWithGate();
  final lessons = content.module('backend/web')!.lessons;

  setUp(() {
    db = memoryDb();
    clock = FixedClock(testEpoch);
  });
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {List<dynamic> extra = const []}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...builtContentOverrides(content),
          ...progressOverrides(db, clock: clock),
          ...extra.cast(),
        ],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> passAll() async {
    final p = ProgressRepository(db, clock);
    for (final r in lessons) {
      await p.markRead(r.id);
      await p.recordQuizScore(r.id, ratio: 1, contentVersion: 1);
    }
  }

  testWidgets('S1 → S8 → exam (pause, resume) → failed result → S1 card', (
    tester,
  ) async {
    await passAll();
    await pumpApp(tester);
    expect(find.text('Sẵn sàng thi cổng Giai đoạn 0 · 35 câu · ~40 phút'), findsOneWidget);
    await _tap(tester, find.text('Vào bài cổng'));
    expect(find.byType(GateIntroScreen), findsOneWidget);
    expect(find.text('35 câu · ~40 phút'), findsOneWidget);
    expect(find.textContaining('chưa qua trong giai đoạn'), findsNothing);

    await _tap(tester, find.text('Bắt đầu'));
    expect(find.byType(GateExamScreen), findsOneWidget);
    expect(find.text('Câu 1/35'), findsOneWidget);
    expect(find.text('Kiểm tra'), findsNothing, reason: 'no check in a gate');
    await _tap(tester, find.byKey(const ValueKey('option-a'))); // wrong
    await _tap(tester, find.text('Đánh dấu xem lại'));
    expect(find.text('Đã đánh dấu'), findsOneWidget);
    await _tap(tester, find.text('Tiếp'));
    expect(find.text('Câu 2/35'), findsOneWidget);

    // Pause → S8 offers to resume.
    await _tap(tester, find.byIcon(Icons.close_rounded));
    expect(find.text('Tạm dừng — bạn có thể quay lại trong 24 giờ'), findsOneWidget);
    await _tap(tester, find.text('Tạm dừng'));
    expect(find.byType(GateIntroScreen), findsOneWidget);
    await pumpUntilFound(tester, find.text('Tiếp tục (1/35)'));
    await _tap(tester, find.text('Tiếp tục (1/35)'));
    expect(find.text('Câu 2/35'), findsOneWidget, reason: 'first unanswered');

    // 8 wrong in all → 27/35 would pass; 9 wrong → 26/35 = 74%.
    for (var i = 2; i <= 35; i++) {
      await _tap(
        tester,
        find.byKey(ValueKey(i <= 9 ? 'option-a' : 'option-b')),
      );
      if (i < 35) await _tap(tester, find.text('Tiếp'));
    }
    await _tap(tester, find.text('Nộp bài'));
    expect(find.text('Nộp bài và xem kết quả?'), findsOneWidget);
    await _tap(tester, find.widgetWithText(TextButton, 'Nộp bài'));

    expect(find.byType(GateResultScreen), findsOneWidget);
    expect(find.text('26/35 · Chưa qua (cần ≥ 75%)'), findsOneWidget);
    expect(find.text('Thi lại'), findsOneWidget);
    final stage = await db.select(db.stageProgress).getSingle();
    expect((stage.attempts, stage.gatePassedAt), (1, null));
    expect(await db.select(db.reviewItem).get(), isEmpty, reason: 'gate ≠ review');

    await _tap(tester, find.text('Về Học tiếp'));
    expect(find.byType(HomeScreen), findsOneWidget);
    await pumpUntilFound(tester, find.textContaining('Cổng GĐ0: 74% — cần 75%.'));
    expect(find.text('Thi lại'), findsOneWidget);
  });

  testWidgets('a passed gate of the only stage → path finished on S1', (
    tester,
  ) async {
    await passAll();
    final quiz = QuizRepository(db, clock);
    final exam = ExamRepository(db, clock, quiz, Random.new);
    final gate = content.gates['gate0']!;
    final a = await exam.startGate(content, gate);
    final byId = {for (final q in gate.questions) q.id: q};
    for (final id in a.questionIds) {
      await quiz.recordAnswer(
        attemptId: a.id,
        kind: QuizKind.gate,
        questionId: id,
        answer: byId[id]!.answer,
        correct: true,
        sourceLesson: null,
      );
    }
    final r = await exam.finishGate(a.id, 0);
    expect(r.passed, isTrue);
    await pumpApp(tester);
    expect(find.text('Bạn đã đi hết lộ trình'), findsOneWidget);
  });

  testWidgets('S2 Quiz module → 15 questions → Module ✓', (tester) async {
    final p = ProgressRepository(db, clock);
    for (final r in lessons) {
      await p.markRead(r.id);
    }
    await pumpApp(tester);
    await _tap(tester, find.text('Lộ trình'));
    await _tap(tester, find.text('web'));
    await _tap(tester, find.text('Quiz module'));
    expect(find.byType(ModuleQuizScreen), findsOneWidget);
    expect(find.text('Câu 1/15'), findsOneWidget);
    for (var i = 1; i <= 15; i++) {
      await _tap(tester, find.byKey(const ValueKey('option-b')));
      await _tap(tester, find.text('Kiểm tra'));
      await _tap(tester, find.text('Tiếp'));
    }
    expect(find.byType(ModuleResultScreen), findsOneWidget);
    expect(find.text('15/15 · Đã qua'), findsOneWidget);
    expect(find.text('Theo bài'), findsOneWidget);
    // Lesson progress untouched (still read).
    final rows = await db.select(db.lessonProgress).get();
    expect(rows.every((r) => r.status == 'read'), isTrue);
    await _tap(tester, find.text('Về Học tiếp'));
    await _tap(tester, find.text('Lộ trình'));
    if (find.text('Quiz module').evaluate().isEmpty) {
      await _tap(tester, find.text('web'));
    }
    await pumpUntilFound(tester, find.text('Module ✓'));
  });

  testWidgets('S1 "Tiếp tục quiz" for an unfinished quiz', (tester) async {
    final quiz = QuizRepository(db, clock);
    final a = await ExamRepository(
      db,
      clock,
      quiz,
      Random.new,
    ).startModule(content, content.module('backend/web')!);
    await quiz.recordAnswer(
      attemptId: a.id,
      kind: QuizKind.module,
      questionId: a.questionIds.first,
      answer: const ['b'],
      correct: true,
      sourceLesson: null,
    );
    await pumpApp(tester);
    final label = 'Tiếp tục quiz: web (1/${a.questionIds.length})';
    await pumpUntilFound(tester, find.text(label));
    await _tap(tester, find.text(label));
    expect(find.byType(ModuleQuizScreen), findsOneWidget);
    expect(find.text('Câu 2/${a.questionIds.length}'), findsOneWidget);
  });

  testWidgets('S10: prefs persist; export → import round trip; reset', (
    tester,
  ) async {
    final files = _Files();
    await pumpApp(tester, extra: [progressFilesProvider.overrideWithValue(files)]);
    await _tap(tester, find.byIcon(Icons.settings_rounded));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Giờ nhắc'), findsNothing, reason: 'E5: hidden');
    await _tap(tester, find.text('EN'));
    await _tap(tester, find.text('Tối'));
    await _tap(tester, find.text('30'));
    final s = SettingsRepository(db);
    expect(await s.get(SettingKeys.contentLang), 'en');
    expect(await s.get(SettingKeys.theme), 'dark');
    expect(await s.get(SettingKeys.reviewMax), '30');
    final container = ProviderScope.containerOf(tester.element(find.byType(LtaApp)));
    expect(container.read(contentLangProvider), ContentLang.en);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await _tap(tester, find.text('Xuất JSON'));
    expect(files.saved, contains('"content_lang"'));

    await _tap(tester, find.text('Đặt lại tiến độ'));
    await _tap(tester, find.widgetWithText(TextButton, 'Đặt lại'));
    expect(find.text('Chắc chắn đặt lại? Không hoàn tác được.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(TextButton, 'Đặt lại'));
    expect(await s.get(SettingKeys.contentLang), isNull);

    files.toPick = 'not a progress file';
    await _tap(tester, find.text('Nhập JSON'));
    await _tap(tester, find.text('Ghi đè'));
    expect(
      find.text('File này không phải bản xuất tiến độ hợp lệ. Tiến độ hiện tại giữ nguyên.'),
      findsOneWidget,
    );

    files.toPick = files.saved;
    await _tap(tester, find.text('Nhập JSON'));
    expect(
      find.text('Ghi đè tiến độ hiện tại bằng file này? Không hoàn tác được.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Ghi đè'));
    expect(find.text('Đã nhập tiến độ.'), findsOneWidget);
    expect(await s.get(SettingKeys.contentLang), 'en');
    await tester.pumpAndSettle();
    expect(container.read(contentLangProvider), ContentLang.en);
  });
}
