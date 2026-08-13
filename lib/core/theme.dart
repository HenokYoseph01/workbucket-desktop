import 'package:flutter/material.dart';

const desktopInk = Color(0xFF203A43);
const desktopPaper = Color(0xFFFFFBF3);
const desktopGold = Color(0xFFF4C95D);

ThemeData buildDesktopTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: desktopInk,
      surface: desktopPaper,
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F0E5),
    cardTheme: const CardThemeData(color: desktopPaper, elevation: 0),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: desktopInk,
      indicatorColor: desktopGold,
      selectedIconTheme: IconThemeData(color: desktopInk),
      unselectedIconTheme: IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.55),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
