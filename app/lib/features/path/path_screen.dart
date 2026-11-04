// S2 Lộ trình (`/path`, `/path/tracks`) — docs/05 S2. "Giai đoạn": stages
// from `path.stages` → modules → lessons, the current stage (or `?stage=n`)
// open. "Theo track": tracks → L1–L4 → modules → lessons with a small stage
// tag, for lookup. Lessons not in content.json show "sắp có". Expansion is
// remembered for the session. The two-column web layout is M7 (docs/05 §9).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/exam_repository.dart';
import '../gate/gate_providers.dart';
import '../../progress/learning_plan.dart';
import '../../progress/lesson_status.dart';
import '../../progress/path_progress.dart';
import '../../progress/plan_provider.dart';
import '../../progress/progress_repository.dart';
import '../../shared/lesson_row.dart';

/// Open/closed state of S2 sections, by key (`s:<stage>`, `m:<track/module>`,
/// `t:<track>`). Absent keys use the screen's default.
class PathExpansionNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void set(String key, bool open) => state = {...state, key: open};
}

final pathExpansionProvider =
    NotifierProvider<PathExpansionNotifier, Map<String, bool>>(
      PathExpansionNotifier.new,
    );

class PathScreen extends ConsumerStatefulWidget {
  const PathScreen({super.key, this.initialStage, this.byTrack = false});

  /// `?stage=n` (docs/05 §3.2): open that stage.
  final int? initialStage;
  final bool byTrack;

  @override
  ConsumerState<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends ConsumerState<PathScreen> {
  @override
  void initState() {
    super.initState();
    _openRequestedStage();
  }

  @override
  void didUpdateWidget(PathScreen old) {
    super.didUpdateWidget(old);
    if (old.initialStage != widget.initialStage) _openRequestedStage();
  }

  void _openRequestedStage() {
    final n = widget.initialStage;
    if (n == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pathExpansionProvider.notifier).set('s:$n', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final plan = ref.watch(learningPlanProvider);
    final stages = ref.watch(stageProgressProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navPath),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(LtaSize.minTouch),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LtaSpace.contentMobile,
              0,
              LtaSpace.contentMobile,
              LtaSpace.s2,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(l.pathByStage)),
                  ButtonSegment(value: true, label: Text(l.pathByTrack)),
                ],
                selected: {widget.byTrack},
                onSelectionChanged: (s) => context.go(
                  s.single ? pathTracksLocation : pathLocation(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          debugPrint('path load failed: $e');
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
        data: (p) {
          final data = _PathData(
            content: ref.watch(contentProvider).requireValue,
            progress: ref.watch(lessonProgressProvider).requireValue,
            stages: stages.value ?? const {},
            plan: p,
            expansion: ref.watch(pathExpansionProvider),
            lang: effectiveLang(ref, context),
            openStage: widget.initialStage ?? p.currentStage,
            onToggle: ref.read(pathExpansionProvider.notifier).set,
            onOpen: (id) => context.push(lessonLocation(id)),
            passedModules: ref.watch(passedModulesProvider).value ?? const {},
            onModuleQuiz: (key) => context.push(moduleQuizLocation(key)),
            onGate: (stage) => context.push(gateLocation(stage)),
          );
          final children = widget.byTrack
              ? _trackView(context, data)
              : _stageView(context, data);
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: LtaSpace.contentMobile,
              vertical: LtaSpace.s2,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LtaSize.homeMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _stageView(BuildContext context, _PathData d) => [
    for (final s in d.content.stages)
      if (stageModules(d.content, s).isNotEmpty) ...[
        _StageSection(stage: s, data: d),
        const SizedBox(height: LtaSpace.s2),
      ],
  ];

  List<Widget> _trackView(BuildContext context, _PathData d) => [
    for (final t in d.content.tracks) ...[
      _TrackSection(track: t, data: d),
      const SizedBox(height: LtaSpace.s2),
    ],
  ];
}

/// Everything the S2 sections read.
class _PathData {
  const _PathData({
    required this.content,
    required this.progress,
    required this.stages,
    required this.plan,
    required this.expansion,
    required this.lang,
    required this.openStage,
    required this.onToggle,
    required this.onOpen,
    required this.passedModules,
    required this.onModuleQuiz,
    required this.onGate,
  });

  /// `track/module` keys with a module quiz ≥ 70% ("Module ✓").
  final Set<String> passedModules;
  final ValueChanged<String> onModuleQuiz;
  final ValueChanged<int> onGate;
  final Content content;
  final Map<String, LessonRecord> progress;
  final Map<int, StageRecord> stages;
  final LearningPlan plan;
  final Map<String, bool> expansion;
  final ContentLang lang;
  final int? openStage;
  final void Function(String key, bool open) onToggle;
  final ValueChanged<String> onOpen;

  bool isOpen(String key, {required bool byDefault}) =>
      expansion[key] ?? byDefault;

  bool containsNext(TrackModule m) => plan.next?.module.key == m.key;

  LessonStatus status(String id) =>
      progress[id]?.status ?? LessonStatus.newLesson;
}

Color _stageColor(LtaColors c, int stage) =>
    c.stage[stage.clamp(0, c.stage.length - 1)];

/// Collapsible header row shared by StageHeader, track and ModuleTile.
class _Header extends StatelessWidget {
  const _Header({
    required this.open,
    required this.onTap,
    required this.title,
    this.subtitle,
    required this.count,
    this.complete = false,
  });

  final bool open;
  final VoidCallback onTap;
  final Widget title;
  final String? subtitle;
  final PathCount count;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    return Semantics(
      expanded: open,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: LtaSize.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: LtaSpace.s2),
            child: Row(
              children: [
                Icon(
                  open
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: LtaSize.icon,
                  color: c.ink2,
                ),
                const SizedBox(width: LtaSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: c.ink2,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: LtaSpace.s2),
                Text(
                  l.pathCount(count.done, count.total),
                  style: t.eyebrow.copyWith(color: c.ink2),
                ),
                if (complete) ...[
                  const SizedBox(width: LtaSpace.s1),
                  Icon(
                    Icons.check_rounded,
                    size: LtaSize.icon,
                    color: c.correct,
                    semanticLabel: l.pathModuleDone,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// StageHeader + its modules (docs/05 §6: left border 4 dp in the stage
/// colour, main-path x/y, gate state).
class _StageSection extends StatelessWidget {
  const _StageSection({required this.stage, required this.data});

  final PathStage stage;
  final _PathData data;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final key = 's:${stage.stage}';
    final open = data.isOpen(key, byDefault: stage.stage == data.openStage);
    final record = data.stages[stage.stage];
    final gate = switch (gateState(record)) {
      GateState.notTaken => l.pathGateNotTaken,
      GateState.passed => l.pathGatePassed,
      GateState.failed => l.pathGateFailed(
        ((record?.bestGateScore ?? 0) * 100).round(),
        (gatePassRatio * 100).round(),
      ),
    };
    final modules = stageModules(data.content, stage);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: _stageColor(c, stage.stage),
            width: LtaSize.stageEdge,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: LtaSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              open: open,
              onTap: () => data.onToggle(key, !open),
              title: Text(
                l
                    .homeStage(stage.stage, stage.title.of(data.lang))
                    .toUpperCase(),
                style: t.eyebrow.copyWith(color: c.ink),
              ),
              subtitle: gate,
              count: stageCount(data.content, stage, data.progress),
            ),
            if (open) ...[
              for (final m in modules)
                _ModuleTile(module: m, data: data, byTrack: false),
              if (stageGate(data.content, stage.stage) != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: LtaSpace.s4,
                    top: LtaSpace.s2,
                    bottom: LtaSpace.s2,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton(
                      onPressed: () => data.onGate(stage.stage),
                      child: Text(l.pathEnterGate),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Theo track" level 1: a track, then L1–L4 with their modules.
class _TrackSection extends StatelessWidget {
  const _TrackSection({required this.track, required this.data});

  final Track track;
  final _PathData data;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final key = 't:${track.id}';
    final modules = [
      for (final lv in track.levels) ...lv.modules,
    ];
    final open = data.isOpen(key, byDefault: modules.any(data.containsNext));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          open: open,
          onTap: () => data.onToggle(key, !open),
          title: Text(
            track.title.of(data.lang),
            style: theme.textTheme.titleMedium,
          ),
          count: PathCount.of([
            for (final m in modules) ...m.lessons,
          ], data.progress),
        ),
        if (open)
          for (final lv in track.levels) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: LtaSpace.s6,
                top: LtaSpace.s2,
              ),
              child: Text(
                l.pathLevel(lv.level, lv.title.of(data.lang)).toUpperCase(),
                style: t.eyebrow.copyWith(color: c.ink2),
              ),
            ),
            for (final m in lv.modules)
              _ModuleTile(module: m, data: data, byTrack: true),
          ],
      ],
    );
  }
}

/// ModuleTile — docs/05 §6: name, x/y, ✓ when complete, lessons, and
/// "Quiz module" once every lesson is read, "Module ✓" once it is passed.
class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.data,
    required this.byTrack,
  });

  final TrackModule module;
  final _PathData data;
  final bool byTrack;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final key = 'm:${module.key}';
    final open = data.isOpen(key, byDefault: data.containsNext(module));
    final count = moduleCount(module, data.progress);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: LtaSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            open: open,
            onTap: () => data.onToggle(key, !open),
            title: Text(
              module.title.of(data.lang),
              style: theme.textTheme.titleSmall,
            ),
            count: count,
            complete: count.complete,
          ),
          if (open) ...[
            for (final r in module.lessons)
              _row(context, l, c, r),
            if (moduleAllRead(module, data.progress))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: LtaSpace.s2),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => data.onModuleQuiz(module.key),
                      child: Text(l.pathModuleQuiz),
                    ),
                    if (data.passedModules.contains(module.key)) ...[
                      const SizedBox(width: LtaSpace.s3),
                      Text(
                        l.pathModulePassed,
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: c.correct,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, L l, LtaColors c, LessonRef r) {
    final lesson = data.content.lessons[r.id];
    final stage = lesson?.stage ?? module.stage;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: LtaSpace.s5),
      child: LessonRow(
        title: r.title.of(data.lang),
        status: data.status(r.id),
        durationMin: r.durationMin,
        optional: !r.mainPath,
        current: r.id == data.plan.next?.id,
        upcoming: lesson == null,
        tag: byTrack ? l.pathStageTag(stage) : null,
        stageColor: _stageColor(c, stage),
        indent: !byTrack && !r.mainPath ? LtaSize.optionalIndent : 0,
        onTap: () => data.onOpen(r.id),
      ),
    );
  }
}
