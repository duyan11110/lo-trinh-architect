// ReviewDueRow — docs/05 §6 / S1: "Ôn hôm nay · 12 câu" + outlined
// "Ôn 5 phút"; hidden when nothing is due.
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../l10n/app_localizations.dart';

class ReviewDueRow extends StatelessWidget {
  const ReviewDueRow({
    super.key,
    required this.count,
    required this.minutes,
    required this.onStart,
  });

  final int count;
  final int minutes;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.reviewHomeTitle, style: theme.textTheme.titleMedium),
            ),
            Text(
              l.reviewCount(count),
              style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
            ),
          ],
        ),
        const SizedBox(height: LtaSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            height: LtaSize.minTap,
            child: OutlinedButton(
              onPressed: onStart,
              child: Text(l.reviewHomeStart(minutes)),
            ),
          ),
        ),
      ],
    );
  }
}
