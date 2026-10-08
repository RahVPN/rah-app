import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rah_app/data/datasources/aether_data_source.dart';
import 'package:rah_app/data/mappers/aether_config_mapper.dart';
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';



class AetherMethodChannelDataSource implements AetherDataSource {
  static const _control = MethodChannel('rah/control');
  static const _events = EventChannel('rah/events');

  Stream<Map<String, dynamic>>? _raw;

  Stream<Map<String, dynamic>> get _stream => _raw ??= _events
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event as Map));

  @override
  Stream<AetherEvent> get states => _stream
      .where((event) => event['type'] == 'state')
      .map(
        (event) => AetherEvent(
          state: AetherState.values.firstWhere(
            (state) => state.name == event['state'],
            orElse: () => AetherState.error,
          ),
          message: event['message'] as String?,
        ),
      );

  @override
  Stream<String> get logs => _stream
      .where((event) => event['type'] == 'log')
      .map((event) => (event['line'] as String?) ?? '');

  @override
  Future<AetherState> currentState() async {
    final value = await _control.invokeMethod<String>('state');
    return AetherState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => AetherState.idle,
    );
  }

  @override
  Future<void> start(AetherConfig config) =>
      _control.invokeMethod('start', AetherConfigMapper.toMap(config));

  @override
  Future<void> stop() => _control.invokeMethod('stop');
}
