// M3 Done (docs/07 §11): the everyday flow at widget level — mở app → Học
// tiếp → đọc tới cuối → quiz (1 câu sai) → kết quả, on an in-memory database
// and a fixed clock. integration_test/everyday_flow_test.dart runs the same
// steps (test/flows/everyday_flow.dart) on the platform database.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/main.dart';
import 'package:lta_app/progress/clock.dart';
import 'package:lta_app/progress/database.dart';

import '../flows/everyday_flow.dart';
import '../helpers.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  testWidgets('open → read → quiz (1 wrong) → result → review next day', (
    tester,
  ) async {
    final clock = FixedClock(testEpoch);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...contentOverrides(), ...progressOverrides(db, clock: clock)],
        child: const LtaApp(locale: Locale('vi')),
      ),
    );
    await tester.pumpAndSettle();

    final r = await runEverydayFlow(tester, db);
    await runReviewNextDay(tester, clock);

    // Review item due one day after the (fixed) answer time.
    final item = (await db.select(db.reviewItem).get()).single;
    expect(
      DateTime.parse(item.dueAt),
      testEpoch.add(const Duration(days: 1)),
    );
    // One finished attempt with every answer stored.
    final attempt = (await db.select(db.quizAttempt).get()).single;
    expect(attempt.score, r.total - 1);
    expect(attempt.total, r.total);
    expect(attempt.finishedAt, isNotNull);
    final answers = await db.select(db.quizAnswer).get();
    expect(answers, hasLength(r.total));
    expect(
      [for (final a in answers) if (a.correct == 0) a.questionId],
      [r.wrongQuestionId],
    );
    final events = await db.select(db.event).get();
    expect(events.where((e) => e.kind == 'quiz_finished'), hasLength(1));
  });
}
