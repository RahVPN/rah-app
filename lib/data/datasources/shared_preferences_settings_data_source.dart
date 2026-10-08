import 'dart:convert';

import 'package:rah_app/data/mappers/aether_config_mapper.dart';
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SharedPreferencesSettingsDataSource {
  SharedPreferencesSettingsDataSource(this._preferences);

  static const _configKey = 'connection_config';
  final SharedPreferencesAsync _preferences;

  Future<AetherConfig?> readConfig() async {
    final saved = await _preferences.getString(_configKey);
    if (saved == null) return null;

    final decoded = jsonDecode(saved);
    if (decoded is! Map) return null;
    return AetherConfigMapper.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<void> writeConfig(AetherConfig config) => _preferences.setString(
    _configKey,
    jsonEncode(AetherConfigMapper.toMap(config)),
  );
}
