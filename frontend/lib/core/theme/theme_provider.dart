import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  final Color seedColor;
  final ThemeMode themeMode;

  ThemeSettings({
    required this.seedColor,
    required this.themeMode,
  });

  ThemeSettings copyWith({
    Color? seedColor,
    ThemeMode? themeMode,
  }) {
    return ThemeSettings(
      seedColor: seedColor ?? this.seedColor,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(ThemeSettings(
    seedColor: const Color(0xFFE65100), // Default Deep Orange
    themeMode: ThemeMode.system,
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('theme_seed_color');
    final modeIndex = prefs.getInt('theme_mode');

    if (colorValue != null || modeIndex != null) {
      state = state.copyWith(
        seedColor: colorValue != null ? Color(colorValue) : null,
        themeMode: modeIndex != null ? ThemeMode.values[modeIndex] : null,
      );
    }
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_seed_color', color.value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});
