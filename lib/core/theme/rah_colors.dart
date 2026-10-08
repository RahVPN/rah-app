import 'package:flutter/material.dart';

class RahColors {
  static bool lightMode = false;

  static Color get ink => lightMode ? const Color(0xFFF3F7F5) : const Color(0xFF0D1519);
  static Color get panel => lightMode ? const Color(0xFFFFFFFF) : const Color(0xFF151F25);
  static Color get panelHigh => lightMode ? const Color(0xFFE8EFEC) : const Color(0xFF1D2A31);
  static Color get line => lightMode ? const Color(0xFFD2DDD8) : const Color(0xFF2A3A43);
  static Color get foam => lightMode ? const Color(0xFF18251F) : const Color(0xFFE6EFF2);
  static Color get mist => lightMode ? const Color(0xFF586B62) : const Color(0xFF8CA1AB);
  static Color get jade => lightMode ? const Color(0xFF087A50) : const Color(0xFF3DDC97);
  static Color get amber => lightMode ? const Color(0xFF925500) : const Color(0xFFFFB547);
  static Color get coral => lightMode ? const Color(0xFFB42318) : const Color(0xFFFF6B6B);
}
