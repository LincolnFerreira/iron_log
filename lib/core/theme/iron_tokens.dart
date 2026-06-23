import 'package:flutter/material.dart';

/// Design tokens espelhando o CSS do IronLog (settings e telas afins).
class IronTokens {
  // Dark
  static const bgDark = Color(0xFF0A0A0C);
  static const s1Dark = Color(0xFF111115);
  static const s2Dark = Color(0xFF18181E);
  static const s3Dark = Color(0xFF22222A);
  static const borderDark = Color(0x12FFFFFF);
  static const border2Dark = Color(0x1FFFFFFF);

  // Light
  static const bgLight = Color(0xFFF2F2F5);
  static const s1Light = Color(0xFFFFFFFF);
  static const s2Light = Color(0xFFEAEAEF);
  static const s3Light = Color(0xFFDDDDE5);
  static const borderLight = Color(0x14000000);
  static const border2Light = Color(0x24000000);

  // Accents (same both modes — adjusted via opacity when needed)
  static const accentDark = Color(0xFFE8FF47);
  static const accentLight = Color(0xFF8AB200);
  static const green = Color(0xFF4DFFB4);
  static const greenLight = Color(0xFF00A36E);
  static const red = Color(0xFFFF5252);
  static const redLight = Color(0xFFD93025);
  static const orange = Color(0xFFFF9A3C);
  static const purple = Color(0xFFA78BFA);

  // Text Dark
  static const textDark = Color(0xFFF0F0F0);
  static const text2Dark = Color(0xFFA0A0B0);
  static const text3Dark = Color(0xFF606070);

  // Text Light
  static const textLight = Color(0xFF0F0F14);
  static const text2Light = Color(0xFF50505E);
  static const text3Light = Color(0xFF9090A0);

  static Color accent(bool dark) => dark ? accentDark : accentLight;
  static Color bg(bool dark) => dark ? bgDark : bgLight;
  static Color s1(bool dark) => dark ? s1Dark : s1Light;
  static Color s2(bool dark) => dark ? s2Dark : s2Light;
  static Color s3(bool dark) => dark ? s3Dark : s3Light;
  static Color border(bool dark) => dark ? borderDark : borderLight;
  static Color border2(bool dark) => dark ? border2Dark : border2Light;
  static Color text(bool dark) => dark ? textDark : textLight;
  static Color text2(bool dark) => dark ? text2Dark : text2Light;
  static Color text3(bool dark) => dark ? text3Dark : text3Light;
  static Color greenC(bool dark) => dark ? green : greenLight;
  static Color redC(bool dark) => dark ? red : redLight;
}
