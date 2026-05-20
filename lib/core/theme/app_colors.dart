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

  // Incognito: subtle warm privacy accent on the light theme (not dark mode).
  static const Color surfaceIncognitoAccent = Color(0xFFFFFBF3);
  static const Color surfaceElevatedIncognitoAccent = Color(0xFFFFF6DC);
  static const Color borderIncognitoAccent = Color(0xFFE8D48A);
  static const Color textMutedIncognitoAccent = Color(0xFF6B6558);
  static const Color hintIncognitoAccent = Color(0xFF8A8478);

  // Loading / analyzing widget accents.
  static const Color loaderGlow = Color(0xFFFFCC00);
  static const Color loaderAccentViolet = Color(0xFF7C5CFF);
  static const Color loaderAccentCyan = Color(0xFF4DD9FF);
  static const Color loaderTrack = Color(0x1FFFFFFF);

  static const double opacityDisabled = 0.6;
  static const double opacityHint = 0.7;
  static const double opacityBorderMuted = 0.4;
  static const double opacityIconMuted = 0.8;
  static const double opacityRiskFill = 0.15;
  static const double opacityWarningFill = 0.14;
  static const double opacityGlowSoft = 0.12;
  static const double opacityGlowStrong = 0.35;
  static const double opacitySweepFade = 0;
  static const double opacityLoaderMesh = 0.52;
  static const double opacityLoaderMeshLight = 0.42;

  static Color get warningBackground => nortonYellow.withValues();

  static Color get errorBackground => surface.withValues();
  static const double opacityRiskTrack = 0.2;

  static Color get hintMuted => textMuted.withValues(alpha: opacityHint);

  static Color get borderMuted =>
      textMuted.withValues(alpha: opacityBorderMuted);

  static Color get iconMuted => textMuted.withValues(alpha: opacityIconMuted);

  static Color get disabledYellow =>
      nortonYellow.withValues(alpha: opacityDisabled);

  static Color get disabledTextPrimary =>
      textPrimary.withValues(alpha: opacityDisabled);

  static Color resolveBackground({required bool incognito}) => background;

  static Color resolveSurface({required bool incognito}) =>
      incognito ? surfaceIncognitoAccent : surface;

  static Color resolveSurfaceElevated({required bool incognito}) =>
      incognito ? surfaceElevatedIncognitoAccent : surface;

  static Color resolveTextPrimary({required bool incognito}) => textPrimary;

  static Color resolveTextMuted({required bool incognito}) =>
      incognito ? textMutedIncognitoAccent : textMuted;

  static Color resolveBorder({required bool incognito}) =>
      incognito ? borderIncognitoAccent : borderBlack;

  static Color resolveHint({required bool incognito}) =>
      incognito ? hintIncognitoAccent : hintMuted;
}
