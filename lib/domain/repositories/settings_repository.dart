
import 'package:rah_app/domain/entities/aether_config.dart';

abstract interface class SettingsRepository {
  Future<AetherConfig?> load();
  Future<void> save(AetherConfig config);
}
