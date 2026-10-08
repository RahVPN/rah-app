

import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';
import 'package:rah_app/domain/repositories/aether_repository.dart';

class AetherUseCases {
  const AetherUseCases(this._repository);

  final AetherRepository _repository;

  Stream<AetherEvent> get states => _repository.states;
  Stream<String> get logs => _repository.logs;

  Future<AetherState> currentState() => _repository.currentState();
  Future<void> connect(AetherConfig config) => _repository.start(config);
  Future<void> disconnect() => _repository.stop();
}
