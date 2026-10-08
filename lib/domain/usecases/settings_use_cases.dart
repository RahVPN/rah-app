

import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/repositories/settings_repository.dart';

class SettingsUseCases {
  const SettingsUseCases(this._repository);

  final SettingsRepository _repository;

  Future<AetherConfig?> load() => _repository.load();
  Future<void> save(AetherConfig config) => _repository.save(config);
}
