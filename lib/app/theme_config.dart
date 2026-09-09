import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/hive_storage_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final hiveStorage = ref.watch(hiveStorageServiceProvider);
  return ThemeModeNotifier(hiveStorage);
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final hiveStorage = ref.watch(hiveStorageServiceProvider);
  return LocaleNotifier(hiveStorage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final HiveStorageService _hive;
  static const String _themeKey = 'app_theme_mode';

  ThemeModeNotifier(this._hive) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = _hive.get<String>(_themeKey);
    if (savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _hive.put(_themeKey, mode.name);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  final HiveStorageService _hive;
  static const String _localeKey = 'app_selected_locale';

  LocaleNotifier(this._hive) : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final savedCode = _hive.get<String>(_localeKey);
    if (savedCode != null) {
      state = Locale(savedCode);
    }
  }

  void setLocale(Locale locale) {
    state = locale;
    _hive.put(_localeKey, locale.languageCode);
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, String>((ref) {
  final hiveStorage = ref.watch(hiveStorageServiceProvider);
  return FontSizeNotifier(hiveStorage);
});

class FontSizeNotifier extends StateNotifier<String> {
  final HiveStorageService _hive;
  static const String _fontSizeKey = 'app_font_size';

  FontSizeNotifier(this._hive) : super('Medium') {
    _loadFontSize();
  }

  void _loadFontSize() {
    final savedSize = _hive.get<String>(_fontSizeKey);
    if (savedSize != null) {
      state = savedSize;
    }
  }

  void setFontSize(String size) {
    state = size;
    _hive.put(_fontSizeKey, size);
  }
}
