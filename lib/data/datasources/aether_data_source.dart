import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';

/// Platform-neutral contract for the thing that actually runs the Aether core.
/// Android: [AetherMethodChannelDataSource] (VpnService in Kotlin).
/// Linux:   [AetherProcessDataSource] (child process driven from Dart).
abstract interface class AetherDataSource {
  Stream<AetherEvent> get states;
  Stream<String> get logs;
  Future<AetherState> currentState();
  Future<void> start(AetherConfig config);
  Future<void> stop();
}
