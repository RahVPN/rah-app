import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:rah_app/data/datasources/aether_data_source.dart';
import 'package:rah_app/data/datasources/aether_method_channel_data_source.dart';
import 'package:rah_app/data/datasources/aether_process_data_source.dart';
import 'package:rah_app/data/datasources/exit_info_http_data_source.dart';
import 'package:rah_app/data/datasources/shared_preferences_settings_data_source.dart';
import 'package:rah_app/data/repositories/aether_repository_impl.dart';
import 'package:rah_app/data/repositories/exit_info_repository_impl.dart';
import 'package:rah_app/data/repositories/settings_repository_impl.dart';
import 'package:rah_app/domain/usecases/aether_use_cases.dart';
import 'package:rah_app/domain/usecases/exit_info_use_cases.dart';
import 'package:rah_app/domain/usecases/settings_use_cases.dart';
import 'package:rah_app/presentation/home/home_page.dart';

/// Composition root: select platform adapters and build presentation inputs.
HomePage createHomePage() {
  final AetherDataSource aetherDataSource = Platform.isLinux
      ? AetherProcessDataSource()
      : AetherMethodChannelDataSource();
  final aetherRepository = AetherRepositoryImpl(aetherDataSource);
  final settingsRepository = SettingsRepositoryImpl(
    SharedPreferencesSettingsDataSource(SharedPreferencesAsync()),
  );
  final exitInfoRepository = ExitInfoRepositoryImpl(ExitInfoHttpDataSource());

  return HomePage(
    connection: AetherUseCases(aetherRepository),
    settings: SettingsUseCases(settingsRepository),
    exitInfo: ExitInfoUseCases(exitInfoRepository),
  );
}
