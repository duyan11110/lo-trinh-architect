// Design tokens — docs/05 §5. The only place in the app allowed to hold
// literal colours, sizes, radii and durations. Widgets read them through
// `Theme.of(context).extension<LtaColors>()!` or the static classes below.
import 'package:flutter/material.dart';

/// Colour tokens (docs/05 §5.1), kept outside [ColorScheme] as a
/// [ThemeExtension].
@immutable
class LtaColors extends ThemeExtension<LtaColors> {
  const LtaColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.correct,
    required this.correctSoft,
    required this.incorrect,
    required this.incorrectSoft,
    required this.codeBg,
    required this.codeInk,
    required this.stage,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color correct;
  final Color correctSoft;
  final Color incorrect;
  final Color incorrectSoft;
  final Color codeBg;
  final Color codeInk;

  /// Stage colours `stage0…4` (5 entries).
  final List<Color> stage;

  /// Colour of the soft shadow (`rgba(23,32,58,.18)`, docs/05 §5.3).
  final Color shadow;

  static const LtaColors light = LtaColors(
    bg: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF1F8),
    ink: Color(0xFF17203A),
    ink2: Color(0xFF4B5570),
    muted: Color(0xFF7B849C),
    line: Color(0xFFD9DEEB),
    accent: Color(0xFF2B4EE6),
    accentSoft: Color(0xFFE3E9FF),
    correct: Color(0xFF1E7F5C),
    correctSoft: Color(0xFFDDF3EA),
    incorrect: Color(0xFFB4342E),
    incorrectSoft: Color(0xFFFBE3E1),
    codeBg: Color(0xFF1B2238),
    codeInk: Color(0xFFE6EAF5),
    stage: [
      Color(0xFFB4342E),
      Color(0xFF1E7F5C),
      Color(0xFF2B4EE6),
      Color(0xFF1B35A8),
      Color(0xFFC77C05),
    ],
    shadow: Color(0x2E17203A),
  );

  static const LtaColors dark = LtaColors(
    bg: Color(0xFF0E1322),
    surface: Color(0xFF161C30),
    surface2: Color(0xFF1E2540),
    ink: Color(0xFFE8EBF5),
    ink2: Color(0xFFB4BBD1),
    muted: Color(0xFF8790AB),
    line: Color(0xFF2B3352),
    accent: Color(0xFF7C95FF),
    accentSoft: Color(0xFF23305E),
    correct: Color(0xFF5CCB9C),
    correctSoft: Color(0xFF143327),
    incorrect: Color(0xFFF08A84),
    incorrectSoft: Color(0xFF3D1A18),
    codeBg: Color(0xFF0A0E1A),
    codeInk: Color(0xFFDDE2F0),
    stage: [
      Color(0xFFF08A84),
      Color(0xFF5CCB9C),
      Color(0xFF7C95FF),
      Color(0xFFB7C4FF),
      Color(0xFFF2B85A),
    ],
    shadow: Color(0x2E17203A),
  );

  @override
  LtaColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentSoft,
    Color? correct,
    Color? correctSoft,
    Color? incorrect,
    Color? incorrectSoft,
    Color? codeBg,
    Color? codeInk,
    List<Color>? stage,
    Color? shadow,
  }) {
    return LtaColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      correct: correct ?? this.correct,
      correctSoft: correctSoft ?? this.correctSoft,
      incorrect: incorrect ?? this.incorrect,
      incorrectSoft: incorrectSoft ?? this.incorrectSoft,
      codeBg: codeBg ?? this.codeBg,
      codeInk: codeInk ?? this.codeInk,
      stage: stage ?? this.stage,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  LtaColors lerp(ThemeExtension<LtaColors>? other, double t) {
    if (other is! LtaColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return LtaColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      correct: l(correct, other.correct),
      correctSoft: l(correctSoft, other.correctSoft),
      incorrect: l(incorrect, other.incorrect),
      incorrectSoft: l(incorrectSoft, other.incorrectSoft),
      codeBg: l(codeBg, other.codeBg),
      codeInk: l(codeInk, other.codeInk),
      stage: [
        for (var i = 0; i < stage.length; i++) l(stage[i], other.stage[i]),
      ],
      shadow: l(shadow, other.shadow),
    );
  }
}

/// 4 dp spacing grid and content margins (docs/05 §5.3).
abstract final class LtaSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;

  /// Content margin on mobile.
  static const double contentMobile = 20;

  /// Content margin on web.
  static const double contentWeb = 32;
}

/// Corner radii (docs/05 §5.3).
abstract final class LtaRadius {
  static const double card = 12;
  static const double button = 10;
  static const double chip = 999;
  static const double code = 8;
}

/// Fixed sizes and strokes named in docs/05 §5–§6.
abstract final class LtaSize {
  /// Material Symbols Rounded size (docs/05 §5.4).
  static const double icon = 22;

  /// Card / divider border width.
  static const double border = 1;

  /// Minimum touch height for list rows and quiz options.
  static const double minTouch = 56;

  /// Minimum tappable size (docs/05 §8).
  static const double minTap = 48;

  /// `SummaryBox` accent frame (docs/05 §6).
  static const double emphasisBorder = 1.5;

  /// `StatusDot` diameter (docs/05 §6).
  static const double statusDot = 10;

  /// Halo width around the current-lesson StatusDot (◉).
  static const double statusHalo = 3;

  /// Share of the scroll at which `BottomActionBar` appears (docs/05 S3).
  static const double actionBarScroll = 0.8;

  /// `ReadingProgress` bar height (docs/05 S3).
  static const double readingProgress = 2;

  /// Max content width of Học tiếp on web (docs/05 S1: 720 px centred).
  static const double homeMaxWidth = 720;

  /// Max reading column on 600–899 dp (docs/05 §9).
  static const double readingMaxWidth = 640;

  /// `TermTooltip` bottom sheet height on mobile (docs/05 §6).
  static const double termSheet = 200;

  /// `DiagramFullScreen` pinch-zoom limit.
  static const double diagramMaxScale = 4;

  /// Quiz card width on 600–899 dp (docs/05 §9).
  static const double quizCardMedium = 560;

  /// Quiz card width from 900 dp (docs/05 §9).
  static const double quizCardWide = 600;

  /// `ExplanationPanel` sheet on mobile: opens at 50% of the screen and can be
  /// dragged up (docs/05 S4).
  static const double explanationSheet = 0.5;
  static const double explanationSheetMin = 0.25;
  static const double explanationSheetMax = 0.9;

  /// Letter badge (A–F) and order-step number on quiz cards.
  static const double quizBadge = 28;

  /// Quiz progress bar (by question, docs/05 S4).
  static const double quizProgress = 4;

  /// StageBar dots (docs/05 §6: current 12 dp, others 8 dp) and the line
  /// joining them.
  static const double stageDot = 8;
  static const double stageDotCurrent = 12;
  static const double stageLine = 2;

  /// StageHeader left border in the stage colour (docs/05 §6: 4 dp).
  static const double stageEdge = 4;

  /// Indent of side-branch rows under their module on S2 (docs/05 S2).
  static const double optionalIndent = 16;

  /// Inline `FillField` width; fixed so it does not hint at the answer length.
  static const double fillField = 160;
}

/// Opacity steps (docs/05 S2: side branches dimmed to 70%).
abstract final class LtaOpacity {
  static const double optional = 0.7;

  /// Soft halo around the "Học tiếp" StatusDot (◉, docs/05 S2).
  static const double halo = 0.25;

  /// Quiz options that are neither the answer nor chosen, after "Kiểm tra"
  /// (docs/05 S4: "các phương án còn lại mờ").
  static const double dimmed = 0.5;
}

/// Elevation and the one soft shadow (docs/05 §5.3).
abstract final class LtaElevation {
  static const double none = 0;

  static List<BoxShadow> soft(LtaColors c) => [
        BoxShadow(
          color: c.shadow,
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -12,
        ),
      ];
}

/// Motion durations and curves (docs/05 §5.5).
abstract final class LtaMotion {
  static const Duration route = Duration(milliseconds: 200);
  static const Duration explanation = Duration(milliseconds: 220);
  static const Duration option = Duration(milliseconds: 150);
  static const Duration language = Duration(milliseconds: 150);
  static const Curve explanationCurve = Curves.easeOutCubic;
}

/// Width breakpoints (docs/05 §9).
abstract final class LtaBreakpoint {
  static const double medium = 600;
  static const double rail = 900;
  static const double wide = 1100;
}

/// Font family names declared in pubspec.yaml (DECISIONS.md E3).
abstract final class LtaFont {
  static const String sans = 'BeVietnamPro';
  static const String mono = 'JetBrainsMono';
}
