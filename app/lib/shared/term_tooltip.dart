// TermTooltip — docs/05 §6/S3: term, short definition, "Học ở: <bài>" chip,
// "Thêm vào ôn" (docs/07 §5.3: creates the `term:<slug>` review item).
// Bottom sheet on every platform for now (web popover is M7).
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../content/models/models.dart';
import '../l10n/app_localizations.dart';
import 'lesson_link_chip.dart';

Future<void> showTermTooltip(
  BuildContext context, {
  required GlossaryEntry entry,
  required ContentLang lang,
  required String? learnedInTitle,
  required bool learnedInAvailable,
  ValueChanged<String>? onOpenLesson,
  bool inReview = false,
  Future<void> Function(GlossaryEntry entry)? onAddReview,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => TermTooltipBody(
      entry: entry,
      lang: lang,
      learnedInTitle: learnedInTitle,
      learnedInAvailable: learnedInAvailable,
      onOpenLesson: onOpenLesson == null
          ? null
          : (id) {
              Navigator.of(sheet).pop();
              onOpenLesson(id);
            },
      inReview: inReview,
      onAddReview: onAddReview,
    ),
  );
}

class TermTooltipBody extends StatefulWidget {
  const TermTooltipBody({
    super.key,
    required this.entry,
    required this.lang,
    required this.learnedInTitle,
    required this.learnedInAvailable,
    this.onOpenLesson,
    this.inReview = false,
    this.onAddReview,
  });

  final GlossaryEntry entry;
  final ContentLang lang;
  final String? learnedInTitle;
  final bool learnedInAvailable;
  final ValueChanged<String>? onOpenLesson;

  /// An active `term:<slug>` item exists already.
  final bool inReview;
  final Future<void> Function(GlossaryEntry entry)? onAddReview;

  @override
  State<TermTooltipBody> createState() => _TermTooltipBodyState();
}

class _TermTooltipBodyState extends State<TermTooltipBody> {
  bool _added = false;
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    await widget.onAddReview!(widget.entry);
    if (mounted) {
      setState(() {
        _busy = false;
        _added = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final text = Theme.of(context).textTheme;
    final l = L.of(context);
    final entry = widget.entry;
    final String addLabel = _added
        ? l.termAdded
        : widget.inReview
        ? l.termInReview
        : l.termAddReview;
    final canAdd = widget.onAddReview != null && !_added && !widget.inReview && !_busy;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LtaSize.termSheet),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LtaSpace.contentMobile,
            0,
            LtaSpace.contentMobile,
            LtaSpace.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name(widget.lang), style: text.titleLarge),
              const SizedBox(height: LtaSpace.s2),
              Text(entry.short(widget.lang), style: text.bodyMedium),
              const SizedBox(height: LtaSpace.s4),
              Wrap(
                spacing: LtaSpace.s2,
                runSpacing: LtaSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l.termLearnedIn,
                    style: text.bodyMedium!.copyWith(color: c.ink2),
                  ),
                  LessonLinkChip(
                    lessonId: entry.introducedIn,
                    title: widget.learnedInTitle,
                    available: widget.learnedInAvailable,
                    onTap: widget.onOpenLesson == null
                        ? null
                        : () => widget.onOpenLesson!(entry.introducedIn),
                  ),
                ],
              ),
              if (widget.onAddReview != null) ...[
                const SizedBox(height: LtaSpace.s4),
                SizedBox(
                  height: LtaSize.minTap,
                  child: OutlinedButton.icon(
                    key: const ValueKey('term-add-review'),
                    onPressed: canAdd ? _add : null,
                    icon: Icon(
                      _added || widget.inReview
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                    ),
                    label: Text(addLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
