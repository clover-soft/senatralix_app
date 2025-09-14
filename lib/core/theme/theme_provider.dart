import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentralix_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Доступные seed‑цвета (10 вариантов)
const kSeedPalette = <Color>[
  Color(0xFF0B4E7A), // синий тёмный
  Color(0xFFE6E3DD), // теплый светлый
  Color(0xFF20A114), // зелёный
  Color(0xFF8E24AA), // фиолетовый
  Color(0xFFFF7043), // оранжевый
  Color(0xFF00897B), // бирюзовый
  Color(0xFF3949AB), // индиго
  Color(0xFF6D4C41), // коричневый
  Color(0xFFFFB300), // янтарный
  Color(0xFF546E7A), // сине‑серый
];

class ThemeState {
  const ThemeState({required this.mode, required this.seedIndex});
  final AppThemeMode mode;
  final int seedIndex; // индекс в kSeedPalette

  ThemeState copyWith({AppThemeMode? mode, int? seedIndex}) => ThemeState(
    mode: mode ?? this.mode,
    seedIndex: seedIndex ?? this.seedIndex,
  );
}

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController(this._storage)
    : super(const ThemeState(mode: AppThemeMode.system, seedIndex: 1)) {
    _load();
  }

  static const _kModeKey = 'theme_mode';
  static const _kSeedKey = 'theme_seed_index';
  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    try {
      final m = await _storage.read(key: _kModeKey);
      final s = await _storage.read(key: _kSeedKey);
      AppThemeMode mode = state.mode;
      int seedIndex = state.seedIndex;
      if (m != null) {
        switch (m) {
          case 'system':
            mode = AppThemeMode.system;
          case 'light':
            mode = AppThemeMode.light;
          case 'dark':
            mode = AppThemeMode.dark;
        }
      }
      if (s != null) {
        final idx = int.tryParse(s);
        if (idx != null && idx >= 0 && idx < kSeedPalette.length) {
          seedIndex = idx;
        }
      }
      state = state.copyWith(mode: mode, seedIndex: seedIndex);
    } catch (_) {
      // игнорируем ошибки чтения
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _storage.write(
      key: _kModeKey,
      value: switch (mode) {
        AppThemeMode.system => 'system',
        AppThemeMode.light => 'light',
        AppThemeMode.dark => 'dark',
      },
    );
  }

  Future<void> setSeedIndex(int index) async {
    if (index < 0 || index >= kSeedPalette.length) return;
    state = state.copyWith(seedIndex: index);
    await _storage.write(key: _kSeedKey, value: index.toString());
  }
}

final themeProvider = StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController(const FlutterSecureStorage());
});
