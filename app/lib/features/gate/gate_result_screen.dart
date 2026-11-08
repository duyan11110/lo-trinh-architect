// Gate result (`/gate/:stage/result/:attemptId`) — docs/05 S6 "Kết quả
// cổng": score as text, a table by track, "Nên đọc lại" (docs/07 §5.4), then
// "Thi lại" (not passed) or "Sang Giai đoạn n+1" (passed). No explanations:
// the gate measures, it does not teach.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/lesson_status.dart';
import '../../progress/path_progress.dart';
import '../../progress/progress_repository.dart';
import '../../progress/quiz_repository.dart';
import '../../shared/empty_state.dart';
import '../../shared/lesson_row.dart';
import 'gate_providers.dart';

class GateResultScreen extends ConsumerWidget {
  const GateResultScreen({super.key, required this.stage, required this.attemptId});

  final int stage;
  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final content = ref.watch(contentProvider);
    final attempt = ref.watch(quizAttemptProvider(attemptId));
    Widget scaffold(Widget body) => Scaffold(appBar: AppBar(), body: body);
    if (content.hasError || attempt.hasError) {
      return scaffold(EmptyState(body: l.contentLoadFailed));
    }
    if (!content.hasValue || !attempt.hasValue) {
      return scaffold(const Center(child: CircularProgressIndicator()));
    }
    final c = content.value!;
    final sg = stageGate(c, stage);
    final a = attempt.value;
    if (sg == null ||
        a == null ||
        a.kind != QuizKind.gate ||
        a.refId != sg.$2.gate ||
        a.score == null) {
      return scaffold(
        Padding(
          padding: const EdgeInsets.all(LtaSpace.contentMobile),
          child: EmptyState(body: l.resultNotFound),
        ),
      );
    }
    final outcome = gateOutcome(c, sg.$2, a);
    final lang = effectiveLang(ref, context);
    final colors = theme.extension<LtaColors>()!;
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    final passed = outcome.ratio >= gatePassRatio;
    final threshold = (gatePassRatio * 100).round();
    final nextStage = c.stages.where((s) => s.stage > stage).firstOrNull;

    Widget button(Widget child) => SizedBox(height: LtaSize.minTouch, child: child);

    final children = <Widget>[
      Text(
        passed
            ? l.resultPassed(outcome.score, outcome.total)
            : l.gateResultNotPassed(outcome.score, outcome.total, threshold),
        style: theme.textTheme.headlineMedium,
      ),
      const SizedBox(height: LtaSpace.s2),
      Text(
        l.gateTitle(stage),
        style: theme.textTheme.bodyLarge!.copyWith(color: colors.ink2),
      ),
      const SizedBox(height: LtaSpace.s6),
      Text(l.gateByTrack, style: theme.textTheme.titleLarge),
      const SizedBox(height: LtaSpace.s2),
      for (final MapEntry(key: track, value: (right, asked))
          in outcome.byTrack.entries)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: LtaSize.minTap),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  track == null
                      ? l.gateCrossTrack
                      : c.track(track)?.title.of(lang) ?? track,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(l.pathCount(right, asked), style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      if (outcome.reread.isNotEmpty) ...[
        const SizedBox(height: LtaSpace.s6),
        Text(l.gateReread, style: theme.textTheme.titleLarge),
        const SizedBox(height: LtaSpace.s1),
        for (final id in outcome.reread)
          LessonRow(
            title: c.lessonTitle(id)?.of(lang) ?? id,
            status: progress[id]?.status ?? LessonStatus.newLesson,
            durationMin: c.lessons[id]?.durationMin,
            upcoming: !c.lessons.containsKey(id),
            onTap: () => context.push(lessonLocation(id)),
          ),
      ],
      const SizedBox(height: LtaSpace.s6),
      if (passed && nextStage != null)
        button(
          FilledButton(
            onPressed: () => context.go(homeLocation),
            child: Text(l.gateNextStage(nextStage.stage)),
          ),
        )
      else if (!passed)
        button(
          FilledButton(
            onPressed: () => context.pushReplacement(gateLocation(stage)),
            child: Text(l.homeRetakeGate),
          ),
        ),
      const SizedBox(height: LtaSpace.s2),
      button(
        TextButton(
          onPressed: () => context.go(homeLocation),
          child: Text(l.resultBackHome),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          LtaSpace.contentMobile,
          LtaSpace.s2,
          LtaSpace.contentMobile,
          LtaSpace.s6,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LtaSize.readingMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
