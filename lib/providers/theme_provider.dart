import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }
  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('themeMode');
    state =
        ThemeMode.values.where((e) => e.name == value).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('themeMode', mode.name);
  }
}

class PaletteNotifier extends StateNotifier<AppPalette> {
  PaletteNotifier() : super(AppPalette.classicInk) {
    _load();
  }
  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('themePalette');
    state =
        AppPalette.values.where((e) => e.name == value).firstOrNull ??
        AppPalette.classicInk;
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('themePalette', palette.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
final themePaletteProvider = StateNotifierProvider<PaletteNotifier, AppPalette>(
  (ref) => PaletteNotifier(),
);
