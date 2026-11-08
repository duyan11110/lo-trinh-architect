// Section containers used by Prose — docs/05 §6: MisconceptionCard,
// TryItPanel, SummaryBox, plus the light card for "Before you start".
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';

/// `surface2` card: belief in bold, arrow, truth.
class MisconceptionCard extends StatelessWidget {
  const MisconceptionCard({super.key, required this.belief, required this.truth});

  final Widget belief;
  final Widget truth;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LtaSpace.s4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(LtaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          belief,
          const SizedBox(height: LtaSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: LtaSpace.s1),
                child: Icon(Icons.arrow_forward_rounded, color: c.accent),
              ),
              const SizedBox(width: LtaSpace.s2),
              Expanded(child: truth),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Thử ngay": lightly accented background.
class TryItPanel extends StatelessWidget {
  const TryItPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LtaSpace.s4),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(LtaRadius.card),
      ),
      child: child,
    );
  }
}

/// Five-line summary: `accent` frame 1.5 dp.
class SummaryBox extends StatelessWidget {
  const SummaryBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LtaSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LtaRadius.card),
        border: Border.all(color: c.accent, width: LtaSize.emphasisBorder),
      ),
      child: child,
    );
  }
}

/// "Bạn cần biết trước": light card.
class PrereqCard extends StatelessWidget {
  const PrereqCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LtaSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LtaRadius.card),
        border: Border.all(color: c.line, width: LtaSize.border),
      ),
      child: child,
    );
  }
}
