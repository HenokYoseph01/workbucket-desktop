import 'package:flutter/material.dart';

enum AppPalette {
  classicInk,
  forestJournal,
  sepiaLibrary,
  plumNotebook,
  midnightBlue,
  monochromePaper,
  rosePetal,
  matchaHoney,
}

extension AppPaletteDetails on AppPalette {
  String get label => const [
    'Classic Ink',
    'Forest Journal',
    'Sepia Library',
    'Plum Notebook',
    'Midnight Blue',
    'Monochrome Paper',
    'Rose Petal',
    'Matcha & Honey',
  ][index];
  Color get seed => const [
    Color(0xFF203A43),
    Color(0xFF315B45),
    Color(0xFF6B4932),
    Color(0xFF65445F),
    Color(0xFF354B6B),
    Color(0xFF111111),
    Color(0xFFA75A7A),
    Color(0xFF9CA764),
  ][index];
  Color get accent => const [
    Color(0xFFF4C95D),
    Color(0xFFC79A45),
    Color(0xFFB7793F),
    Color(0xFFD09A5B),
    Color(0xFF8FAED1),
    Color(0xFF888888),
    Color(0xFFE7A5B8),
    Color(0xFFF1E8C7),
  ][index];
  Color get lightPaper => const [
    Color(0xFFFFFBF3),
    Color(0xFFFBF8ED),
    Color(0xFFFFF5DF),
    Color(0xFFFFF7FA),
    Color(0xFFF6F8FC),
    Colors.white,
    Color(0xFFFFF5F8),
    Color(0xFFFCFAEF),
  ][index];
  Color get darkPaper => const [
    Color(0xFF111A1D),
    Color(0xFF121C17),
    Color(0xFF211813),
    Color(0xFF20171F),
    Color(0xFF111821),
    Colors.black,
    Color(0xFF21151B),
    Color(0xFF1B1D13),
  ][index];
}

ThemeData buildDesktopTheme(AppPalette palette, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final paper = dark ? palette.darkPaper : palette.lightPaper;
  final seedForeground =
      ThemeData.estimateBrightnessForColor(palette.seed) == Brightness.dark
      ? Colors.white
      : Colors.black;
  final accentForeground =
      ThemeData.estimateBrightnessForColor(palette.accent) == Brightness.dark
      ? Colors.white
      : Colors.black;
  var scheme = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: brightness,
    surface: paper,
  );
  final primary = palette == AppPalette.monochromePaper
      ? (dark ? Colors.white : Colors.black)
      : palette.seed;
  final onPrimary = palette == AppPalette.monochromePaper
      ? (dark ? Colors.black : Colors.white)
      : seedForeground;
  final primaryContainer = Color.alphaBlend(
    primary.withValues(alpha: dark ? .24 : .13),
    paper,
  );
  final accentContainer = Color.alphaBlend(
    palette.accent.withValues(alpha: dark ? .25 : .22),
    paper,
  );
  scheme = scheme.copyWith(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: scheme.onSurface,
    secondary: palette.accent,
    onSecondary: accentForeground,
    secondaryContainer: accentContainer,
    onSecondaryContainer: scheme.onSurface,
    tertiary: palette.accent,
    onTertiary: accentForeground,
    tertiaryContainer: accentContainer,
    onTertiaryContainer: scheme.onSurface,
    surface: paper,
  );
  final raised = Color.alphaBlend(
    scheme.primary.withValues(alpha: dark ? .09 : .045),
    paper,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    cardTheme: CardThemeData(
      color: raised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.seed,
      indicatorColor: palette.accent,
      selectedIconTheme: IconThemeData(color: accentForeground),
      unselectedIconTheme: const IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: raised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: raised,
      contentTextStyle: TextStyle(color: scheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
