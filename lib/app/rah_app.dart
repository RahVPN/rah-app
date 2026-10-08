import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rah_app/core/constants/app_info.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rah_app/l10n/generated/app_localizations.dart';
import 'package:rah_app/core/theme/app_theme.dart';
import 'package:rah_app/core/theme/rah_colors.dart';
import 'package:rah_app/presentation/home/home_page.dart';
import 'package:rah_app/presentation/splash/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('fa'));
final ValueNotifier<bool> appLightTheme = ValueNotifier(false);

class RahApp extends StatefulWidget {
  const RahApp({required this.homePage, super.key});

  final HomePage homePage;

  @override
  State<RahApp> createState() => _RahAppState();
}

class _RahAppState extends State<RahApp> {
  Locale _locale = const Locale('fa');
  bool _lightTheme = false;

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_localeChanged);
    appLightTheme.addListener(_themeChanged);
    SharedPreferencesAsync().getString('app_locale').then((value) {
      if (value != null && (value == 'fa' || value == 'en')) {
        appLocale.value = Locale(value);
      }
    });
    SharedPreferencesAsync().getBool('light_theme').then((value) {
      if (value != null) appLightTheme.value = value;
    });
  }

  void _localeChanged() {
    setState(() => _locale = appLocale.value);
    SharedPreferencesAsync().setString('app_locale', _locale.languageCode);
  }

  void _setLocale(Locale locale) {
    appLocale.value = locale;
  }

  void _themeChanged() {
    setState(() => _lightTheme = appLightTheme.value);
    SharedPreferencesAsync().setBool('light_theme', _lightTheme);
  }

  @override
  void dispose() {
    appLocale.removeListener(_localeChanged);
    appLightTheme.removeListener(_themeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = buildAppTheme(light: true);
    final darkTheme = buildAppTheme();
    RahColors.lightMode = _lightTheme;
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _lightTheme ? ThemeMode.light : ThemeMode.dark,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: buildSystemUiOverlayStyle(light: _lightTheme),
        child: child ?? const SizedBox.shrink(),
      ),
      home: SplashPage(
        homePage: widget.homePage,
        onLocaleChanged: _setLocale,
        locale: _locale,
      ),
    );
  }
}
