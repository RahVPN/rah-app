

import 'package:rah_app/data/datasources/shared_preferences_settings_data_source.dart';
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._dataSource);

  final SharedPreferencesSettingsDataSource _dataSource;

  @override
  Future<AetherConfig?> load() => _dataSource.readConfig();

  @override
  Future<void> save(AetherConfig config) => _dataSource.writeConfig(config);
}
