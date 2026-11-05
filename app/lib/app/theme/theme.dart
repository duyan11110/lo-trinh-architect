// ThemeData built from tokens — docs/05 §5.6.
import 'package:flutter/material.dart';

import 'text.dart';
import 'tokens.dart';

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.light ? LtaColors.light : LtaColors.dark;
  final text = LtaText.theme(c);
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(LtaRadius.button),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: LtaFont.sans,
    colorScheme: ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.surface,
      secondary: c.accentSoft,
      onSecondary: c.ink,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.ink2,
      error: c.incorrect,
      onError: c.surface,
      outline: c.line,
      outlineVariant: c.line,
      surfaceContainerHighest: c.surface2,
    ),
    scaffoldBackgroundColor: c.bg,
    textTheme: text,
    iconTheme: IconThemeData(color: c.ink2, size: LtaSize.icon),
    extensions: [c, LtaText.of(c)],
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      surfaceTintColor: c.bg,
      elevation: LtaElevation.none,
      scrolledUnderElevation: LtaElevation.none,
      titleTextStyle: text.titleLarge,
      iconTheme: IconThemeData(color: c.ink2, size: LtaSize.icon),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: c.surface,
      indicatorColor: c.accentSoft,
      elevation: LtaElevation.none,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: LtaSize.icon,
          color: states.contains(WidgetState.selected) ? c.accent : c.ink2,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelLarge!.copyWith(
          color: states.contains(WidgetState.selected) ? c.accent : c.ink2,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.accentSoft,
      selectedIconTheme: IconThemeData(color: c.accent, size: LtaSize.icon),
      unselectedIconTheme: IconThemeData(color: c.ink2, size: LtaSize.icon),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.surface,
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.accent,
        side: BorderSide(color: c.line, width: LtaSize.border),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: c.surface,
      elevation: LtaElevation.none,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LtaRadius.card),
        side: BorderSide(color: c.line, width: LtaSize.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface2,
      side: BorderSide(color: c.line, width: LtaSize.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LtaRadius.chip),
      ),
      labelStyle: text.bodyMedium,
    ),
    dividerTheme: DividerThemeData(
      color: c.line,
      thickness: LtaSize.border,
      space: LtaSize.border,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: c.surface,
      elevation: LtaElevation.none,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
