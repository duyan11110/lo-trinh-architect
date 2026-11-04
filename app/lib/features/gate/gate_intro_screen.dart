// S8 Bài cổng: giới thiệu (`/gate/:stage`) — docs/05 S8, §3.3 "Luồng cổng":
// question count, estimated time, pass mark, "no explanations, can pause",
// the attempt history, and "Bắt đầu" (or "Tiếp tục" for an exam paused
// < 24 h). Not finished with the stage's main path → a soft warning; the
// exam stays open.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/locations.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/exam_repository.dart';
import '../../progress/learning_plan.dart';
import '../../progress/path_progress.dart';
import '../../progress/progress_repository.dart';
import '../../shared/empty_state.dart';
import 'gate_providers.dart';

class GateIntroScreen extends ConsumerStatefulWidget {
  const GateIntroScreen({super.key, required this.stage});

  final int stage;

  @override
  ConsumerState<GateIntroScreen> createState() => _GateIntroScreenState();
}

class _GateIntroScreenState extends ConsumerState<GateIntroScreen> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final content = await ref.read(contentProvider.future);
    final sg = stageGate(content, widget.stage);
    if (sg == null) return;
    final attempt = await ref
        .read(examRepositoryProvider)
        .startGate(content, sg.$2);
    if (!mounted) return;
    setState(() => _starting = false);
    await context.push(gateExamLocation(widget.stage, attempt.id));
    if (mounted) ref.invalidate(pausedGateProvider(widget.stage));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final content = ref.watch(contentProvider);
    final progress = ref.watch(lessonProgressProvider);
    Widget scaffold(Widget body) => Scaffold(
      appBar: AppBar(title: Text(l.gateTitle(widget.stage))),
      body: body,
    );
    if (content.hasError || progress.hasError) {
      return scaffold(EmptyState(body: l.contentLoadFailed));
    }
    if (!content.hasValue || !progress.hasValue) {
      return scaffold(const Center(child: CircularProgressIndicator()));
    }
    final sg = stageGate(content.value!, widget.stage);
    if (sg == null) {
      return scaffold(
        Padding(
          padding: const EdgeInsets.all(LtaSpace.contentMobile),
          child: EmptyState(body: l.gateNone),
        ),
      );
    }
    final (stage, gate) = sg;
    final count = stageCount(content.value!, stage, progress.value!);
    final remaining = count.total - count.done;
    final history = ref.watch(gateHistoryProvider(gate.gate)).value ?? const [];
    final paused = ref.watch(pausedGateProvider(widget.stage)).value;
    final n = gate.questions.length < GateSpec.questions
        ? gate.questions.length
        : GateSpec.questions;
    final date = DateFormat('dd/MM/yyyy', Localizations.localeOf(context).toLanguageTag());
    final threshold = (gatePassRatio * 100).round();
    final body = theme.textTheme.bodyLarge!;

    return scaffold(
      ListView(
        padding: const EdgeInsets.all(LtaSpace.contentMobile),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: LtaSize.readingMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(LtaSpace.s5),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(LtaRadius.card),
                      border: Border.all(color: c.line, width: LtaSize.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.gateIntroSize(n, GateSpec.minutes),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: LtaSpace.s3),
                        Text(l.gatePassRule(threshold), style: body),
                        const SizedBox(height: LtaSpace.s2),
                        Text(l.gateNoExplanations, style: body),
                      ],
                    ),
                  ),
                  if (remaining > 0) ...[
                    const SizedBox(height: LtaSpace.s4),
                    Text(
                      l.gateRemaining(remaining),
                      style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
                    ),
                  ],
                  const SizedBox(height: LtaSpace.s5),
                  SizedBox(
                    height: LtaSize.minTouch,
                    child: FilledButton(
                      onPressed: _starting ? null : _start,
                      child: Text(
                        paused == null
                            ? l.gateStart
                            : l.gateResume(
                                paused.answers.values
                                    .where((a) => a.answer.isNotEmpty)
                                    .length,
                                paused.questionIds.length,
                              ),
                      ),
                    ),
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: LtaSpace.s6),
                    Text(l.gateHistory, style: theme.textTheme.titleMedium),
                    const SizedBox(height: LtaSpace.s2),
                    for (final h in history)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: LtaSize.minTap),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.gateHistoryRow(
                                  date.format(h.finishedAt.toLocal()),
                                  h.score,
                                  h.total,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            if (h.passed)
                              Text(
                                l.statusPassed,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: c.correct,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
