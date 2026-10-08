
import 'package:flutter/material.dart';

import 'rah_colors.dart';

abstract final class AppTextStyles {
  static TextStyle mutedBodySmall(ThemeData theme) =>
      theme.textTheme.bodySmall!.copyWith(color: RahColors.mist);

  static TextStyle hintBodySmall(ThemeData theme) =>
      theme.textTheme.bodySmall!.copyWith(color: RahColors.mist, height: 1.6);

  static TextStyle mutedBodyMedium(ThemeData theme) =>
      theme.textTheme.bodyMedium!.copyWith(color: RahColors.mist, height: 1.6);

  static TextStyle sectionLabel(ThemeData theme) =>
      theme.textTheme.labelLarge!.copyWith(color: RahColors.mist);

  static TextStyle connectedTimer(ThemeData theme) =>
      theme.textTheme.titleLarge!.copyWith(
        color: RahColors.foam,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle logLine(Color color) => TextStyle(
    fontFamily: 'monospace',
    fontSize: 11.5,
    height: 1.4,
    color: color,
  );
}
