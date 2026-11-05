// QuizOption — docs/05 §6: card ≥ 56 dp, 1.5 dp border, text wraps, the
// whole card is tappable; `Semantics(selected:)`, label "Phương án A, …"
// (§8). Right/wrong is never colour only: ✓/✗ icons and the "Bạn chọn" note.
import 'package:flutter/material.dart';

import '../../../app/theme/text.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'quiz_text.dart';

enum QuizOptionKind { radio, checkbox }

enum QuizOptionState { idle, selected, correct, wrong, dimmed }

class QuizOption extends StatelessWidget {
  const QuizOption({
    super.key,
    required this.letter,
    required this.text,
    required this.kind,
    required this.state,
    required this.chosen,
    this.onTap,
    this.note,
  });

  final String letter;
  final String text;
  final QuizOptionKind kind;
  final QuizOptionState state;

  /// Picked by the learner (before or after "Kiểm tra").
  final bool chosen;
  final VoidCallback? onTap;

  /// Small label under the text ("Bạn chọn").
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final l = L.of(context);
    final (border, fill, badgeFill, badgeInk) = switch (state) {
      QuizOptionState.idle => (c.line, c.surface, c.surface2, c.ink2),
      QuizOptionState.selected => (c.accent, c.accentSoft, c.accent, c.surface),
      QuizOptionState.correct => (c.correct, c.correctSoft, c.correct, c.surface),
      QuizOptionState.wrong => (c.incorrect, c.incorrectSoft, c.incorrect, c.surface),
      QuizOptionState.dimmed => (c.line, c.surface, c.surface2, c.muted),
    };
    final icon = switch (state) {
      QuizOptionState.correct => Icon(Icons.check_rounded, color: c.correct, size: LtaSize.icon),
      QuizOptionState.wrong => Icon(Icons.close_rounded, color: c.incorrect, size: LtaSize.icon),
      _ => null,
    };
    final radius = BorderRadius.circular(LtaRadius.card);
    final badgeShape = kind == QuizOptionKind.radio
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(LtaRadius.code));
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final card = AnimatedContainer(
      duration: disableAnimations ? Duration.zero : LtaMotion.option,
      constraints: const BoxConstraints(minHeight: LtaSize.minTouch),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: border, width: LtaSize.emphasisBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: LtaSpace.s3, vertical: LtaSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: LtaSize.quizBadge,
            height: LtaSize.quizBadge,
            alignment: Alignment.center,
            decoration: ShapeDecoration(color: badgeFill, shape: badgeShape),
            child: Text(letter, style: theme.textTheme.labelLarge!.copyWith(color: badgeInk)),
          ),
          const SizedBox(width: LtaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuizText(text, style: t.quizOption),
                if (note != null) ...[
                  const SizedBox(height: LtaSpace.s1),
                  Text(note!.toUpperCase(), style: t.eyebrow.copyWith(color: border)),
                ],
              ],
            ),
          ),
          if (icon != null) ...[const SizedBox(width: LtaSpace.s2), icon],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: chosen,
      label: l.quizOptionSemantics(letter, text),
      excludeSemantics: true,
      child: Opacity(
        opacity: state == QuizOptionState.dimmed ? LtaOpacity.dimmed : 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(borderRadius: radius, onTap: onTap, child: card),
        ),
      ),
    );
  }
}
