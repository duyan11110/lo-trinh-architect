// BottomActionBar — docs/05 §6: sticky, SafeArea, one primary action and an
// optional secondary one; hidden/visible by scroll (decided by the caller).
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.primary,
    this.secondary,
    this.note,
  });

  /// Full-width button (filled or outlined).
  final Widget primary;

  /// Text button or second button under [primary].
  final Widget? secondary;

  /// Small line under the actions ("Lần trước: 4/6").
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    return Material(
      color: c.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: c.line, width: LtaSize.border),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LtaSpace.contentMobile,
              LtaSpace.s3,
              LtaSpace.contentMobile,
              LtaSpace.s2,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LtaSize.readingMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: LtaSize.minTouch, child: primary),
                    if (note != null) ...[
                      const SizedBox(height: LtaSpace.s1),
                      Text(
                        note!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (secondary != null) ...[
                      const SizedBox(height: LtaSpace.s1),
                      SizedBox(height: LtaSize.minTap, child: secondary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
