import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/rah_app.dart';
import 'data/datasources/aether_data_source.dart';
import 'data/datasources/aether_method_channel_data_source.dart';
import 'data/datasources/aether_process_data_source.dart';
import 'data/datasources/exit_info_http_data_source.dart';
import 'data/datasources/shared_preferences_settings_data_source.dart';
import 'data/repositories/aether_repository_impl.dart';
import 'data/repositories/exit_info_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/usecases/aether_use_cases.dart';
import 'domain/usecases/exit_info_use_cases.dart';
import 'domain/usecases/settings_use_cases.dart';
import 'presentation/home/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';





@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔥 Background message: ${message.messageId}');
  debugPrint('📦 Data: ${message.data}');
  debugPrint('🔔 Title: ${message.notification?.title}');
  debugPrint('📝 Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is configured for Android only (firebase_options.dart); no Linux support in the plugins.
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register before other asynchronous startup work so the native messaging
    // plugin can dispatch messages while the app is backgrounded.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    final fcmToken = await messaging.getToken();
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('🔥 Foreground message: ${message.messageId}');
      debugPrint('📦 Data: ${message.data}');
      debugPrint('🔔 Title: ${message.notification?.title}');
      debugPrint('📝 Body: ${message.notification?.body}');
    });

    await FirebaseMessaging.instance.subscribeToTopic('all');

    debugPrint('FCM Token: $fcmToken');
  }

  final AetherDataSource aetherDataSource = Platform.isLinux
      ? AetherProcessDataSource()
      : AetherMethodChannelDataSource();
  final aetherRepository = AetherRepositoryImpl(aetherDataSource);
  final settingsRepository = SettingsRepositoryImpl(
    SharedPreferencesSettingsDataSource(SharedPreferencesAsync()),
  );
  final exitInfoRepository = ExitInfoRepositoryImpl(ExitInfoHttpDataSource());

  runApp(
    RahApp(
      homePage: HomePage(
        connection: AetherUseCases(aetherRepository),
        settings: SettingsUseCases(settingsRepository),
        exitInfo: ExitInfoUseCases(exitInfoRepository),
      ),
    ),
  );
}
