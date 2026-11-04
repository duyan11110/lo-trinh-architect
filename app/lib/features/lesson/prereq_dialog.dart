// S5 Hộp thoại tiền đề — docs/05 S5, docs/04 §2 `prereqs`. Shown before S3
// renders a lesson whose openable prereqs are not all `passed`, once per
// lesson (`prereq_warned`). "Học bài trước" opens the first missing prereq
// and remembers the lesson the reader meant to open, so S6 can offer
// "Quay lại: <bài>" after that prereq's quiz is passed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locations.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/lesson_status.dart';
import '../../progress/path_progress.dart';
import '../../progress/progress_repository.dart';
import '../../shared/lesson_row.dart';

/// The lesson put "in the queue" by "Học bài trước" (docs/05 S5). Session
/// memory only.
class PrereqReturnNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? lessonId) => state = lessonId;
}

final prereqReturnProvider = NotifierProvider<PrereqReturnNotifier, String?>(
  PrereqReturnNotifier.new,
);

/// The lesson S6 should offer to return to after [passedLessonId] was
/// passed: the queued lesson, if [passedLessonId] is one of its prereqs.
Lesson? prereqReturnTarget(
  Content content,
  String? queued,
  String passedLessonId,
) {
  final target = queued == null ? null : content.lessons[queued];
  if (target == null || !target.prereqs.contains(passedLessonId)) return null;
  return target;
}

/// Wraps S3: decides whether S5 applies, shows it, then renders [child]
/// ("Cứ đọc", dismissed, or nothing to warn about) or opens a prereq instead.
class PrereqGate extends ConsumerStatefulWidget {
  const PrereqGate({
    super.key,
    required this.content,
    required this.lesson,
    required this.child,
  });

  final Content content;
  final Lesson lesson;
  final Widget child;

  @override
  ConsumerState<PrereqGate> createState() => _PrereqGateState();
}

class _PrereqGateState extends ConsumerState<PrereqGate> {
  late bool _cleared;

  @override
  void initState() {
    super.initState();
    // No openable prereq: render at once (no extra frame).
    _cleared = !hasOpenablePrereqs(widget.content, widget.lesson);
    if (!_cleared) _check();
  }

  Future<void> _check() async {
    final repo = ref.read(progressRepositoryProvider);
    final lesson = widget.lesson;
    final self = await repo.get(lesson.id);
    final progress = <String, LessonRecord>{};
    for (final id in lesson.prereqs) {
      final r = await repo.get(id);
      if (r != null) progress[id] = r;
    }
    final missing = missingPrereqs(widget.content, lesson, progress);
    if (!mounted) return;
    if ((self?.prereqWarned ?? false) || missing.isEmpty) {
      setState(() => _cleared = true);
      return;
    }
    await repo.markPrereqWarned(lesson.id);
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => PrereqDialog(
        content: widget.content,
        missing: missing,
        progress: progress,
      ),
    );
    if (!mounted) return;
    if (choice == null) {
      setState(() => _cleared = true);
      return;
    }
    ref.read(prereqReturnProvider.notifier).set(lesson.id);
    context.pushReplacement(lessonLocation(choice));
  }

  @override
  Widget build(BuildContext context) =>
      _cleared ? widget.child : Scaffold(appBar: AppBar());
}

/// The dialog itself. Pops the id of the prereq to open, or `null` for
/// "Cứ đọc".
class PrereqDialog extends ConsumerWidget {
  const PrereqDialog({
    super.key,
    required this.content,
    required this.missing,
    required this.progress,
  });

  final Content content;

  /// Prereqs not passed, in declared order (non-empty).
  final List<String> missing;
  final Map<String, LessonRecord> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final lang = effectiveLang(ref, context);
    return AlertDialog(
      title: Text(l.prereqWarning(missing.length)),
      contentPadding: const EdgeInsets.fromLTRB(
        LtaSpace.s5,
        LtaSpace.s4,
        LtaSpace.s5,
        0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in missing)
                LessonRow(
                  title: content.lessonTitle(id)?.of(lang) ?? id,
                  status: progress[id]?.status ?? LessonStatus.newLesson,
                  durationMin: content.lessons[id]?.durationMin,
                  onTap: () => Navigator.of(context).pop(id),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(missing.first),
          child: Text(l.prereqLearnFirst),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.prereqReadAnyway),
        ),
      ],
    );
  }
}
