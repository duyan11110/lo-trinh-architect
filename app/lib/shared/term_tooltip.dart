// TermTooltip — docs/05 §6/S3: term, short definition, "Học ở: <bài>" chip,
// "Thêm vào ôn" (docs/07 §5.3: creates the `term:<slug>` review item).
// Bottom sheet below 900 dp; from 900 dp (web layout, docs/05 §9) a popover
// next to the tapped term when the tap position is known (M7). Both close on
// a tap outside or `Escape`.
import 'package:flutter/material.dart';

import '../app/layout.dart';
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

  /// Global tap position; with the two-column layout it anchors a popover.
  Offset? anchor,
}) {
  Widget body(BuildContext route) => TermTooltipBody(
      entry: entry,
      lang: lang,
      learnedInTitle: learnedInTitle,
      learnedInAvailable: learnedInAvailable,
      onOpenLesson: onOpenLesson == null
          ? null
          : (id) {
              Navigator.of(route).pop();
              onOpenLesson(id);
            },
      inReview: inReview,
      onAddReview: onAddReview,
    );
  if (anchor != null && LtaLayout.of(context).twoColumn) {
    final c = Theme.of(context).extension<LtaColors>()!;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: LtaMotion.option,
      pageBuilder: (route, _, _) => CustomSingleChildLayout(
        delegate: _PopoverLayout(anchor),
        child: SizedBox(
          width: LtaSize.termPopover,
          child: Material(
            key: const ValueKey('term-popover'),
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LtaRadius.card),
              side: BorderSide(color: c.line, width: LtaSize.border),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LtaRadius.card),
                boxShadow: LtaElevation.soft(c),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: LtaSpace.s4),
                child: body(route),
              ),
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: body,
  );
}

/// Places the popover under the tap (above it when there is no room), kept
/// inside the window with a 16 dp margin.
class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().deflate(const EdgeInsets.all(LtaSpace.s4));

  @override
  Offset getPositionForChild(Size size, Size child) {
    const m = LtaSpace.s4;
    final below = anchor.dy + LtaSpace.s3;
    final y = below + child.height + m <= size.height
        ? below
        : (anchor.dy - LtaSpace.s3 - child.height).clamp(m, size.height);
    final x = (anchor.dx - child.width / 2).clamp(
      m,
      (size.width - child.width - m).clamp(m, size.width),
    );
    return Offset(x, y.toDouble());
  }

  @override
  bool shouldRelayout(_PopoverLayout old) => old.anchor != anchor;
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
