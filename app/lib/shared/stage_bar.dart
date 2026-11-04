// StageBar — docs/05 §6: one dot per stage joined by a line; the current
// stage is 12 dp, the others 8 dp; `stage[i]` once its gate is passed,
// `line` before. Tapping a dot opens `/path?stage=n` (docs/05 S1).
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../l10n/app_localizations.dart';

class StageBar extends StatelessWidget {
  const StageBar({
    super.key,
    required this.stages,
    required this.current,
    required this.passedGates,
    this.onTapStage,
  });

  /// Stage numbers in `path.stages` order (only stages in content.json).
  final List<int> stages;

  /// Smallest stage without a passed gate; `null` when all are passed.
  final int? current;
  final Set<int> passedGates;
  final ValueChanged<int>? onTapStage;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final l = L.of(context);
    Color stageColor(int s) => c.stage[s.clamp(0, c.stage.length - 1)];

    Widget dot(int s) {
      final passed = passedGates.contains(s);
      final isCurrent = s == current;
      final size = isCurrent ? LtaSize.stageDotCurrent : LtaSize.stageDot;
      final Widget mark = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: passed ? stageColor(s) : (isCurrent ? c.surface : c.line),
          border: isCurrent && !passed
              ? Border.all(color: stageColor(s), width: LtaSize.stageLine)
              : null,
        ),
      );
      return Semantics(
        button: onTapStage != null,
        selected: isCurrent,
        label: l.stageLabel(s),
        child: InkResponse(
          onTap: onTapStage == null ? null : () => onTapStage!(s),
          radius: LtaSize.minTap / 2,
          child: SizedBox.square(
            dimension: LtaSize.minTap,
            child: Center(child: mark),
          ),
        ),
      );
    }

    final children = <Widget>[];
    for (final (i, s) in stages.indexed) {
      if (i > 0) {
        final prev = stages[i - 1];
        children.add(
          Expanded(
            child: Container(
              height: LtaSize.stageLine,
              color: passedGates.contains(prev) ? stageColor(prev) : c.line,
            ),
          ),
        );
      }
      children.add(dot(s));
    }
    return Row(children: children);
  }
}
