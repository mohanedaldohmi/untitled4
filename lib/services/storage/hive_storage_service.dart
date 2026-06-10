import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class HiveStorageService {
  static Box<dynamic>? _settingsBox;
  static Box<dynamic>? _favoritesBox;

  static Box<dynamic> get settingsBox => _settingsBox!;
  static Box<dynamic> get favoritesBox => _favoritesBox!;

  /// Opens all Hive boxes — called once in main.dart
  static Future<void> openBoxes() async {
    try {
      _settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
      _favoritesBox = await Hive.openBox<dynamic>(AppConstants.favoritesBox);
      AppLogger.info('Hive boxes opened successfully');
    } catch (e, stack) {
      AppLogger.fatal('Failed to open Hive boxes', e, stack);
      rethrow;
    }
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  static T? getSetting<T>(String key) {
    return _settingsBox?.get(key) as T?;
  }

  static Future<void> saveSetting<T>(String key, T value) async {
    await _settingsBox?.put(key, value);
  }

  static Future<void> removeSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  static bool hasSetting(String key) {
    return _settingsBox?.containsKey(key) ?? false;
  }

  // ─── Favorites ────────────────────────────────────────────────────────────

  static List<dynamic> getFavorites() {
    return _favoritesBox?.values.toList() ?? [];
  }

  static Future<void> addFavorite(String url, dynamic data) async {
    await _favoritesBox?.put(url, data);
  }

  static Future<void> removeFavorite(String url) async {
    await _favoritesBox?.delete(url);
  }

  static bool isFavorite(String url) {
    return _favoritesBox?.containsKey(url) ?? false;
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _settingsBox?.clear();
    await _favoritesBox?.clear();
  }

  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}
