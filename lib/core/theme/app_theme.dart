import 'package:flutter/material.dart';

import 'rah_colors.dart';

ThemeData buildAppTheme({bool light = false}) {
  RahColors.lightMode = light;
  final scheme = light ? const ColorScheme.light(
    primary: Color(0xFF087A50),
    onPrimary: Colors.white,
    secondary: Color(0xFF925500),
    onSecondary: Colors.white,
    error: Color(0xFFB42318),
    surface: Color(0xFFF3F7F5),
    onSurface: Color(0xFF18251F),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFE8EFEC),
    surfaceContainerHighest: Color(0xFFE8EFEC),
    outline: Color(0xFF586B62),
    outlineVariant: Color(0xFFD2DDD8),
  ) : ColorScheme.dark(
    primary: RahColors.jade,
    onPrimary: RahColors.ink,
    secondary: RahColors.amber,
    onSecondary: RahColors.ink,
    error: RahColors.coral,
    onError: RahColors.ink,
    surface: RahColors.ink,
    onSurface: RahColors.foam,
    surfaceContainerLow: RahColors.panel,
    surfaceContainer: RahColors.panel,
    surfaceContainerHigh: RahColors.panelHigh,
    surfaceContainerHighest: RahColors.panelHigh,
    outline: RahColors.mist,
    outlineVariant: RahColors.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: light ? Brightness.light : Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: RahColors.ink,
    fontFamily: 'Vazirmatn',
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RahColors.panelHigh,
      selectedColor: RahColors.jade.withValues(alpha: 0.18),
      side: BorderSide(color: RahColors.line),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: RahColors.foam, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: RahColors.jade, fontSize: 13),
    ),
    dividerTheme: DividerThemeData(
      color: RahColors.line,
      space: 1,
      thickness: 1,
    ),
  );
}
