// LessonRow — docs/05 §6: StatusDot + title + duration (mono, right); 56 dp;
// side branches dimmed with an "optional" tag; lessons not in content.json
// dimmed with a "sắp có" tag and not tappable (docs/04 §2).
import 'package:flutter/material.dart';

import '../app/theme/text.dart';
import '../app/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'status_dot.dart';

class LessonRow extends StatelessWidget {
  const LessonRow({
    super.key,
    required this.title,
    required this.status,
    this.durationMin,
    this.optional = false,
    this.current = false,
    this.upcoming = false,
    this.tag,
    this.stageColor,
    this.indent = 0,
    this.onTap,
  });

  final String title;
  final LessonStatus status;
  final int? durationMin;
  final bool optional;

  /// The "Học tiếp" lesson (◉).
  final bool current;

  /// Not in `content.lessons` yet: "sắp có", dimmed, [onTap] ignored.
  final bool upcoming;

  /// Small mono label before the duration (S2 "Theo track": "GĐ0").
  final String? tag;

  /// StatusDot fill for `passed` (docs/05 S2: stage colour).
  final Color? stageColor;

  /// Leading indent (S2 side branches).
  final double indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: LtaSpace.s2),
      child: Row(
        children: [
          SizedBox(width: indent),
          StatusDot(
            status: status,
            current: current,
            optional: optional,
            stageColor: stageColor,
          ),
          const SizedBox(width: LtaSpace.s3),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: current ? FontWeight.w500 : FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: LtaSpace.s2),
            Text(l.lessonOptionalTag, style: t.eyebrow),
          ],
          if (upcoming) ...[
            const SizedBox(width: LtaSpace.s2),
            Text(l.lessonUpcoming, style: t.eyebrow.copyWith(color: c.muted)),
          ],
          if (tag != null) ...[
            const SizedBox(width: LtaSpace.s2),
            Text(tag!, style: t.eyebrow.copyWith(color: c.ink2)),
          ],
          if (durationMin != null) ...[
            const SizedBox(width: LtaSpace.s2),
            Text(
              l.durationMinutes(durationMin!),
              style: t.eyebrow.copyWith(color: c.ink2),
            ),
          ],
        ],
      ),
    );
    if (optional || upcoming) {
      row = Opacity(opacity: LtaOpacity.optional, child: row);
    }
    return InkWell(
      onTap: upcoming ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LtaSize.minTouch),
        child: Align(alignment: AlignmentDirectional.centerStart, child: row),
      ),
    );
  }
}
