// S1 Học tiếp (`/`) — docs/05 S1, minimal (docs/05 §12 step 2): stage line,
// NextLessonCard (start / next / gate ready / finished / nothing new), "Đang
// dở" and "Module hiện tại"; StageBar → `/path?stage=n` (M4). Opening a
// lesson goes through S5 in S3. ReviewDueRow (M5) starts today's review
// session. M6: GateReadyCard opens S8, the failed-gate copy with "Nên đọc
// lại", "Tiếp tục quiz" for an unfinished quiz (docs/05 §10) and the "Có nội
// dung mới" line (docs/05 S1, docs/07 §7).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/locations.dart';
import '../../app/router.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/learning_plan.dart';
import '../../progress/plan_provider.dart';
import '../../progress/progress_repository.dart';
import '../../progress/review_repository.dart';
import '../../shared/lesson_row.dart';
import '../../shared/review_due_row.dart';
import '../../shared/stage_bar.dart';
import '../../shared/status_dot.dart';
import '../../content/content_update.dart';
import '../../progress/exam_repository.dart';
import '../../progress/path_progress.dart';
import '../../progress/quiz_repository.dart';
import '../gate/gate_providers.dart';
import '../lesson/lesson_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final plan = ref.watch(learningPlanProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            tooltip: l.settingsTitle,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          debugPrint('home load failed: $e');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(LtaSpace.s5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.contentLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: LtaSpace.s4),
                  TextButton(
                    onPressed: () => ref.invalidate(contentProvider),
                    child: Text(l.contentRetry),
                  ),
                ],
              ),
            ),
          );
        },
        data: (p) => _HomeBody(
          plan: p,
          openQuiz: ref.watch(openQuizProvider).value,
          newVersion: switch (ref.watch(contentUpdateProvider)) {
            final u when u.phase == ContentUpdatePhase.available =>
              u.manifest?.contentVersion,
            _ => null,
          },
          gateOutcome: p.gateReady && p.currentStage != null
              ? ref.watch(lastGateOutcomeProvider(p.currentStage!)).value
              : null,
          content: ref.watch(contentProvider).requireValue,
          progress: ref.watch(lessonProgressProvider).requireValue,
          passedGates: ref.watch(passedGatesProvider).requireValue,
          lang: effectiveLang(ref, context),
          review: ref.watch(reviewOverviewProvider).value,
          onStartReview: () async {
            final id = await startReviewSession(ref);
            if (id != null && context.mounted) {
              context.push(reviewSessionLocation(id));
            }
          },
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.plan,
    required this.openQuiz,
    required this.newVersion,
    required this.gateOutcome,
    required this.content,
    required this.progress,
    required this.passedGates,
    required this.lang,
    required this.review,
    required this.onStartReview,
  });

  final LearningPlan plan;
  final OpenQuiz? openQuiz;

  /// A newer content version found by the last check.
  final int? newVersion;

  /// Last finished exam of the current stage's gate (failed-gate card).
  final GateOutcome? gateOutcome;
  final Content content;
  final Map<String, LessonRecord> progress;
  final Set<int> passedGates;
  final ContentLang lang;
  final ReviewOverview? review;
  final VoidCallback onStartReview;

  LessonStatus _status(String id) =>
      progress[id]?.status ?? LessonStatus.newLesson;

  /// Title and route of an unfinished quiz; `null` when its content is gone.
  (String, String)? _resumeTarget(L l, OpenQuiz q) {
    switch (q.kind) {
      case QuizKind.lesson:
        final t = content.lessonTitle(q.refId);
        if (t == null || !content.quizzes.containsKey(q.refId)) return null;
        return (t.of(lang), quizLocation(q.refId));
      case QuizKind.module:
        final m = content.module(q.refId);
        return m == null
            ? null
            : (m.title.of(lang), moduleQuizLocation(q.refId));
      case QuizKind.gate:
        final s = content.stages.where((s) => s.gate == q.refId).firstOrNull;
        return s == null
            ? null
            : (l.gateTitle(s.stage), gateExamLocation(s.stage, q.attemptId));
      case QuizKind.review:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    void open(String id) => context.push(lessonLocation(id));

    final stage = plan.currentStage;
    final stageInfo = stage == null
        ? null
        : content.stages.firstWhere((s) => s.stage == stage);
    final module = plan.next?.module ?? plan.pendingQuiz.firstOrNull?.module;

    final resume = openQuiz == null ? null : _resumeTarget(l, openQuiz!);
    final layout = LtaLayout.of(context);
    final card = _NextLessonCard(
      plan: plan,
      content: content,
      lang: lang,
      onOpen: open,
      gateOutcome: gateOutcome,
      progress: progress,
    );
    final reviewRow = (review?.dueTotal ?? 0) > 0
        ? ReviewDueRow(
            count: review!.dueTotal,
            minutes: review!.minutes,
            onStart: onStartReview,
          )
        : null;
    // docs/05 S1: side by side from 1200 px.
    final twoUp =
        reviewRow != null &&
        MediaQuery.sizeOf(context).width >= LtaBreakpoint.homeTwoUp;
    final children = <Widget>[
      if (newVersion != null)
        Padding(
          padding: const EdgeInsets.only(bottom: LtaSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.contentNewAvailable(newVersion!),
                  style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
                ),
              ),
              TextButton(
                onPressed: () => context.push(settingsContentLocation),
                child: Text(l.contentUpdateAction),
              ),
            ],
          ),
        ),
      if (stageInfo != null) ...[
        Text(
          l.homeStage(stageInfo.stage, stageInfo.title.of(lang)).toUpperCase(),
          style: t.eyebrow,
        ),
        StageBar(
          stages: [for (final s in content.stages) s.stage],
          current: stage,
          passedGates: passedGates,
          onTapStage: (n) => context.go(pathLocation(stage: n)),
        ),
        Text(
          l.homeToGate(plan.remainingToGate),
          style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
        ),
        const SizedBox(height: LtaSpace.s5),
      ],
      if (twoUp)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card),
            const SizedBox(width: LtaSpace.s4),
            Expanded(child: reviewRow),
          ],
        )
      else
        card,
      if (resume != null) ...[
        const SizedBox(height: LtaSpace.s4),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(LtaSize.minTouch),
            alignment: AlignmentDirectional.centerStart,
          ),
          onPressed: () => context.push(resume.$2),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            l.homeResumeQuiz(resume.$1, openQuiz!.answered, openQuiz!.total),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      if (reviewRow != null && !twoUp) ...[
        const SizedBox(height: LtaSpace.s5),
        reviewRow,
      ],
      if (plan.inProgress.isNotEmpty) ...[
        const SizedBox(height: LtaSpace.s6),
        Text(l.homeInProgress, style: theme.textTheme.titleMedium),
        const SizedBox(height: LtaSpace.s1),
        for (final id in plan.inProgress)
          LessonRow(
            title: content.lessonTitle(id)?.of(lang) ?? id,
            status: _status(id),
            durationMin: content.lessons[id]?.durationMin,
            onTap: () => open(id),
          ),
      ],
      if (module != null) ...[
        const SizedBox(height: LtaSpace.s6),
        Text(l.homeCurrentModule, style: theme.textTheme.titleMedium),
        const SizedBox(height: LtaSpace.s1),
        for (final r in module.lessons)
          LessonRow(
            title: r.title.of(lang),
            status: _status(r.id),
            durationMin: r.durationMin,
            optional: !r.mainPath,
            current: r.id == plan.next?.id,
            onTap: content.lessons.containsKey(r.id) ? () => open(r.id) : null,
          ),
      ],
    ];

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: layout.margin,
        vertical: LtaSpace.s4,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LtaSize.homeMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// NextLessonCard — docs/05 §6: one raised card; default / gateReady /
/// finished (+ "nothing new yet" when every available lesson is read).
class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({
    required this.plan,
    required this.content,
    required this.lang,
    required this.onOpen,
    required this.gateOutcome,
    required this.progress,
  });

  final LearningPlan plan;
  final Content content;
  final ContentLang lang;
  final ValueChanged<String> onOpen;
  final GateOutcome? gateOutcome;
  final Map<String, LessonRecord> progress;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final next = plan.next;

    Widget button(String label, VoidCallback? onPressed) => SizedBox(
      height: LtaSize.minTouch,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );

    final List<Widget> body;
    if (plan.finished) {
      body = [Text(l.homeFinished, style: theme.textTheme.titleLarge)];
    } else if (plan.gateReady) {
      final stage = plan.currentStage!;
      final hasGate = stageGate(content, stage) != null;
      final failed = gateOutcome;
      void enter() => context.push(gateLocation(stage));
      body = [
        if (failed == null) ...[
          Text(
            l.gateReady(stage, GateSpec.questions, GateSpec.minutes),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: LtaSpace.s4),
          button(l.homeEnterGate, hasGate ? enter : null),
        ] else ...[
          Text(
            l.gateFailed(
              stage,
              (failed.ratio * 100).round(),
              (gatePassRatio * 100).round(),
              failed.reread.length,
            ),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: LtaSpace.s4),
          button(l.homeRetakeGate, hasGate ? enter : null),
          if (failed.reread.isNotEmpty) ...[
            const SizedBox(height: LtaSpace.s2),
            for (final id in failed.reread)
              LessonRow(
                title: content.lessonTitle(id)?.of(lang) ?? id,
                status: progress[id]?.status ?? LessonStatus.newLesson,
                durationMin: content.lessons[id]?.durationMin,
                upcoming: !content.lessons.containsKey(id),
                onTap: () => onOpen(id),
              ),
          ],
        ],
        if (next != null) ...[
          const SizedBox(height: LtaSpace.s2),
          TextButton(
            onPressed: () => onOpen(next.id),
            child: Text(l.homeStudyAhead(next.stage)),
          ),
        ],
      ];
    } else if (next != null) {
      final pos = lessonPosition(content, next.id);
      body = [
        Text(
          (plan.fresh
                  ? l.homeStartEyebrow(next.stage)
                  : l.homeNextEyebrow(
                      next.module.title.of(lang),
                      next.ref.durationMin,
                    ))
              .toUpperCase(),
          style: t.eyebrow,
        ),
        const SizedBox(height: LtaSpace.s2),
        Text(
          next.ref.title.of(lang),
          style: theme.textTheme.titleLarge,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (pos != null) ...[
          const SizedBox(height: LtaSpace.s1),
          Text(
            l.homeLessonInModule(pos.index, pos.total),
            style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
          ),
        ],
        const SizedBox(height: LtaSpace.s4),
        button(l.navContinue, () => onOpen(next.id)),
      ];
    } else {
      body = [Text(l.homeNoNewLesson, style: theme.textTheme.titleMedium)];
    }

    return Container(
      padding: const EdgeInsets.all(LtaSpace.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LtaRadius.card),
        border: Border.all(color: c.line, width: LtaSize.border),
        boxShadow: LtaElevation.soft(c),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: body,
      ),
    );
  }
}
