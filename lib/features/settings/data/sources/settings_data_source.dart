import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/di/core_providers.dart';
import '../../domain/models/display_settings.dart';

class SettingsDataSource {
  final LocalDatabase _database;
  static const _key = 'display_settings';

  SettingsDataSource(this._database);

  Future<DisplaySettings> getDisplaySettings() async {
    final rows = await _database.read((executor) => executor.runSelect(
          'SELECT value FROM app_metadata WHERE key = ?',
          [_key],
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

  Future<void> saveDisplaySettings(DisplaySettings settings) async {
    final value = jsonEncode(settings.toJson());
    final now = DateTime.now().toUtc().toIso8601String();

    await _database.transaction((executor) async {
      await executor.runCustom(
        'INSERT OR REPLACE INTO app_metadata (key, value, updated_at_utc) VALUES (?, ?, ?)',
        [_key, value, now],
      );
    });
  }
}

final settingsDataSourceProvider = Provider<SettingsDataSource>((ref) {
  return SettingsDataSource(ref.watch(localDatabaseProvider));
});
