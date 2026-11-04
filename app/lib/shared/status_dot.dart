// StatusDot — docs/05 §6: 10 dp, ✓ drawn with a CustomPainter.
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import '../progress/lesson_status.dart';

export '../progress/lesson_status.dart';

class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.status,
    this.stageColor,
    this.current = false,
    this.optional = false,
  });

  final LessonStatus status;

  /// ◉ — the "Học tiếp" lesson: accent with a soft halo (docs/05 S2).
  final bool current;

  /// Side branch: same symbol, dimmed.
  final bool optional;

  /// Fill for `passed`; defaults to `accent`.
  final Color? stageColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LtaColors>()!;
    final l = L.of(context);
    final label = switch (status) {
      LessonStatus.newLesson => l.statusNew,
      LessonStatus.opened => l.statusOpened,
      LessonStatus.read => l.statusRead,
      LessonStatus.passed => l.statusPassed,
    };
    Widget dot = CustomPaint(
      size: const Size.square(LtaSize.statusDot),
      painter: _DotPainter(status, c, stageColor ?? c.accent),
    );
    if (current) {
      dot = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: LtaOpacity.halo),
              spreadRadius: LtaSize.statusHalo,
            ),
          ],
        ),
        child: CustomPaint(
          size: const Size.square(LtaSize.statusDot),
          painter: _DotPainter(LessonStatus.read, c, c.accent),
        ),
      );
    }
    if (optional) dot = Opacity(opacity: LtaOpacity.optional, child: dot);
    return Semantics(label: label, child: dot);
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.status, this.c, this.stageColor);

  final LessonStatus status;
  final LtaColors c;
  final Color stageColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = LtaSize.border;
    final fill = Paint()..style = PaintingStyle.fill;
    switch (status) {
      case LessonStatus.newLesson:
        canvas.drawCircle(center, r - LtaSize.border / 2, ring..color = c.muted);
      case LessonStatus.opened:
        canvas.drawCircle(center, r - LtaSize.border / 2, ring..color = c.accent);
      case LessonStatus.read:
        canvas.drawCircle(center, r, fill..color = c.accent);
      case LessonStatus.passed:
        canvas.drawCircle(center, r, fill..color = stageColor);
        final check = Path()
          ..moveTo(size.width * 0.28, size.height * 0.52)
          ..lineTo(size.width * 0.44, size.height * 0.68)
          ..lineTo(size.width * 0.74, size.height * 0.36);
        canvas.drawPath(
          check,
          ring
            ..color = c.surface
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.status != status || old.c != c || old.stageColor != stageColor;
}
