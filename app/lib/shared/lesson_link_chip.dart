// LessonLinkChip — docs/05 §6: StatusDot + title; `upcoming` = dimmed, not
// tappable, for ids not present in content.json.
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'status_dot.dart';

class LessonLinkChip extends StatelessWidget {
  const LessonLinkChip({
    super.key,
    required this.lessonId,
    required this.title,
    required this.available,
    this.status = LessonStatus.newLesson,
    this.onTap,
  });

  final String lessonId;

  /// Lesson title in the reading language, `null` when unknown (the id is
  /// shown instead).
  final String? title;

  /// `false` → upcoming chip ("sắp có").
  final bool available;
  final LessonStatus status;
  final VoidCallback? onTap;

  bool get upcoming => !available;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final text = Theme.of(context).textTheme;
    final l = L.of(context);
    final label = title ?? lessonId;
    final fg = upcoming ? c.muted : c.ink;
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LtaSpace.s3,
        vertical: LtaSpace.s1,
      ),
      decoration: BoxDecoration(
        color: upcoming ? c.bg : c.surface2,
        borderRadius: BorderRadius.circular(LtaRadius.chip),
        border: Border.all(color: c.line, width: LtaSize.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!upcoming) ...[
            StatusDot(status: status),
            const SizedBox(width: LtaSpace.s2),
          ],
          Flexible(
            child: Text(
              upcoming ? '$label · ${l.lessonUpcoming}' : label,
              style: text.bodyMedium!.copyWith(color: fg),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (upcoming) {
      return Semantics(enabled: false, child: chip);
    }
    return Semantics(
      button: true,
      link: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(LtaRadius.chip),
        onTap: onTap,
        child: chip,
      ),
    );
  }
}
