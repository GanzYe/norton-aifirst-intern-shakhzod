import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
  static const Color nortonYellow = Color(0xFFFFCC00);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF757575);
  static const Color borderBlack = Color(0xFF000000);
  static const Color shadow = Color(0x42000000);
  static const Color safeGreen = Color(0xFF2E7D32);
  static const Color suspiciousOrange = Color(0xFFEF6C00);
  static const Color dangerousRed = Color(0xFFC62828);

  static const double opacityDisabled = 0.6;
  static const double opacityHint = 0.7;
  static const double opacityBorderMuted = 0.4;
  static const double opacityIconMuted = 0.8;
  static const double opacityRiskFill = 0.15;
  static const double opacityRiskTrack = 0.2;

  static Color get hintMuted => textMuted.withValues(alpha: opacityHint);

  static Color get borderMuted =>
      textMuted.withValues(alpha: opacityBorderMuted);

  static Color get iconMuted => textMuted.withValues(alpha: opacityIconMuted);

  static Color get disabledYellow =>
      nortonYellow.withValues(alpha: opacityDisabled);

  static Color get disabledTextPrimary =>
      textPrimary.withValues(alpha: opacityDisabled);
}
