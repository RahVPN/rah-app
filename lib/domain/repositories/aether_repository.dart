
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';

abstract interface class AetherRepository {
  Stream<AetherEvent> get states;
  Stream<String> get logs;
  Future<AetherState> currentState();
  Future<void> start(AetherConfig config);
  Future<void> stop();
}
