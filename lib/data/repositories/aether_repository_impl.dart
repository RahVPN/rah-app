

import 'package:rah_app/data/datasources/aether_data_source.dart';
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';
import 'package:rah_app/domain/repositories/aether_repository.dart';




class AetherRepositoryImpl implements AetherRepository {
  const AetherRepositoryImpl(this._dataSource);

  final AetherDataSource _dataSource;

  @override
  Stream<AetherEvent> get states => _dataSource.states;

  @override
  Stream<String> get logs => _dataSource.logs;

  @override
  Future<AetherState> currentState() => _dataSource.currentState();

  @override
  Future<void> start(AetherConfig config) => _dataSource.start(config);

  @override
  Future<void> stop() => _dataSource.stop();
}
