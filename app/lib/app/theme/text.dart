// Type scale — docs/05 §5.2.
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Text styles that do not have a slot in [TextTheme] (eyebrow, code, quiz),
/// exposed as a [ThemeExtension]. Standard roles live in [LtaText.theme].
@immutable
class LtaText extends ThemeExtension<LtaText> {
  const LtaText({
    required this.eyebrow,
    required this.code,
    required this.quizQuestion,
    required this.quizOption,
  });

  factory LtaText.of(LtaColors c) => LtaText(
        eyebrow: TextStyle(
          fontFamily: LtaFont.mono,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 1.2,
          color: c.muted,
        ),
        code: TextStyle(
          fontFamily: LtaFont.mono,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.55,
          color: c.codeInk,
          fontFeatures: const [
            FontFeature.disable('liga'),
            FontFeature.disable('calt'),
          ],
        ),
        quizQuestion: TextStyle(
          fontFamily: LtaFont.sans,
          fontSize: 19,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: c.ink,
        ),
        quizOption: TextStyle(
          fontFamily: LtaFont.sans,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: c.ink,
        ),
      );

  /// Eyebrow / meta: mono 11.5, uppercase (apply `toUpperCase` at the call site).
  final TextStyle eyebrow;

  /// Code: mono 13, ligatures off.
  final TextStyle code;
  final TextStyle quizQuestion;
  final TextStyle quizOption;

  /// Reading-body size range in sp (docs/05 §5.2: 17 default, 15–21).
  static const double readingMin = 15;
  static const double readingDefault = 17;
  static const double readingMax = 21;

  /// Reading line-height steps of the `Aa` sheet (docs/05 S3: 2 steps; both
  /// ≥ 1.55 for Vietnamese diacritics, §5.2).
  static const List<double> readingLineHeights = [1.6, 1.8];

  /// Upper clamp for `MediaQuery.textScaler` on reading text.
  static const double maxTextScale = 1.6;

  /// Maps the docs/05 §5.2 table onto [TextTheme]:
  /// headlineMedium = Display/H1, titleLarge = H2, bodyLarge = reading body,
  /// bodyMedium/labelLarge = UI body, labelSmall = eyebrow.
  static TextTheme theme(LtaColors c) {
    TextStyle sans(double size, FontWeight w, double h, Color color) =>
        TextStyle(
          fontFamily: LtaFont.sans,
          fontSize: size,
          fontWeight: w,
          height: h,
          color: color,
        );
    final eyebrow = LtaText.of(c).eyebrow;
    return TextTheme(
      headlineMedium:
          sans(26, FontWeight.w700, 1.2, c.ink).copyWith(letterSpacing: -0.3),
      titleLarge: sans(20, FontWeight.w700, 1.3, c.ink),
      titleMedium: sans(15, FontWeight.w500, 1.45, c.ink),
      bodyLarge: sans(readingDefault, FontWeight.w400, 1.6, c.ink),
      bodyMedium: sans(15, FontWeight.w400, 1.45, c.ink),
      bodySmall: sans(15, FontWeight.w400, 1.45, c.ink2),
      labelLarge: sans(15, FontWeight.w500, 1.45, c.ink),
      labelMedium: eyebrow,
      labelSmall: eyebrow,
    );
  }

  @override
  LtaText copyWith({
    TextStyle? eyebrow,
    TextStyle? code,
    TextStyle? quizQuestion,
    TextStyle? quizOption,
  }) =>
      LtaText(
        eyebrow: eyebrow ?? this.eyebrow,
        code: code ?? this.code,
        quizQuestion: quizQuestion ?? this.quizQuestion,
        quizOption: quizOption ?? this.quizOption,
      );

  @override
  LtaText lerp(ThemeExtension<LtaText>? other, double t) {
    if (other is! LtaText) return this;
    return LtaText(
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      code: TextStyle.lerp(code, other.code, t)!,
      quizQuestion: TextStyle.lerp(quizQuestion, other.quizQuestion, t)!,
      quizOption: TextStyle.lerp(quizOption, other.quizOption, t)!,
    );
  }
}

/// Syntax colours for `CodeBlock`. Code blocks are dark in both themes
/// (`codeBg`), so the palette is taken from the dark tokens regardless of the
/// current brightness. Keys are highlight.js class names.
abstract final class LtaCodeSyntax {
  static Map<String, Color> get colors {
    const d = LtaColors.dark;
    return {
      'keyword': d.accent,
      'built_in': d.accent,
      'selector-tag': d.accent,
      'literal': d.stage[4],
      'number': d.stage[4],
      'string': d.correct,
      'regexp': d.correct,
      'symbol': d.correct,
      'attr': d.stage[3],
      'attribute': d.stage[3],
      'title': d.stage[3],
      'type': d.stage[3],
      'class': d.stage[3],
      'function': d.stage[3],
      'section': d.stage[3],
      'variable': d.incorrect,
      'template-variable': d.incorrect,
      'meta': d.muted,
      'comment': d.muted,
      'quote': d.muted,
    };
  }
}
