import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/di/core_providers.dart';
import '../../domain/models/display_settings.dart';

class SettingsDataSource {
  final LocalDatabase _database;
  static const shabadKey = 'display_settings_shabad';
  static const baniKey = 'display_settings_bani';
  static const boldTextKey = 'is_bold_text_enabled';
  static const themeModeKey = 'app_theme_mode';

  SettingsDataSource(this._database);

  Future<DisplaySettings> getDisplaySettings(String key) async {
    final rows = await _database.read((executor) => executor.runSelect(
          'SELECT value FROM app_metadata WHERE key = ?',
          [key],
        ));

    if (rows.isEmpty) {
      return DisplaySettings.defaults();
    }

    final value = rows.first['value'] as String;
    try {
      return DisplaySettings.fromJson(jsonDecode(value));
    } catch (_) {
      return DisplaySettings.defaults();
    }
  }

  Future<void> saveDisplaySettings(String key, DisplaySettings settings) async {
    final value = jsonEncode(settings.toJson());
    final now = DateTime.now().toUtc().toIso8601String();

    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT OR REPLACE INTO app_metadata (key, value, updated_at_utc) VALUES (?, ?, ?)',
        [key, value, now],
      );
    });
  }

  Future<bool> getBoldTextSettings() async {
    final rows = await _database.read((executor) => executor.runSelect(
          'SELECT value FROM app_metadata WHERE key = ?',
          [boldTextKey],
        ));

    if (rows.isEmpty) {
      return false;
    }

    final value = rows.first['value'] as String;
    return value == 'true';
  }

  Future<void> saveBoldTextSettings(bool isBold) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT OR REPLACE INTO app_metadata (key, value, updated_at_utc) VALUES (?, ?, ?)',
        [boldTextKey, isBold.toString(), now],
      );
    });
  }

  Future<ThemeMode> getThemeMode() async {
    final rows = await _database.read((executor) => executor.runSelect(
          'SELECT value FROM app_metadata WHERE key = ?',
          [themeModeKey],
        ));

    if (rows.isEmpty) {
      return ThemeMode.light;
    }

    final value = rows.first['value'] as String;
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final value = mode == ThemeMode.dark ? 'dark' : 'light';

    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT OR REPLACE INTO app_metadata (key, value, updated_at_utc) VALUES (?, ?, ?)',
        [themeModeKey, value, now],
      );
    });
  }
}

final settingsDataSourceProvider = Provider<SettingsDataSource>((ref) {
  return SettingsDataSource(ref.watch(localDatabaseProvider));
});
