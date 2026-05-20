import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.nortonYellow,
      surface: AppColors.background,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimary,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.dangerousRed,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      bodyMedium: AppTextStyles.resultBody,
    ),
    cardTheme: CardThemeData(
      elevation: AppSizes.cardElevation,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(
          color: AppColors.borderBlack,
          width: AppSizes.borderThin,
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.nortonYellow,
        disabledBackgroundColor: AppColors.disabledYellow,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.disabledTextPrimary,
        side: const BorderSide(
          color: AppColors.borderBlack,
          width: AppSizes.borderThick,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: AppTextStyles.analyzeButton,
      ),
    ),
  );

  /// Full dark theme applied while Incognito (on-device / private) mode is on.
  static ThemeData get incognito => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundIncognito,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.nortonYellow,
      onPrimary: AppColors.textPrimary,
      surface: AppColors.surfaceIncognito,
      onSurface: AppColors.textPrimaryIncognito,
      outline: AppColors.borderIncognito,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundIncognito,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimaryIncognito,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.dangerousRed,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryIncognito,
      ),
      bodyMedium: TextStyle(
        height: AppSizes.bodyLineHeight,
        color: AppColors.textPrimaryIncognito,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: AppSizes.cardElevation,
      color: AppColors.surfaceIncognito,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(
          color: AppColors.borderIncognito,
          width: AppSizes.borderThin,
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.nortonYellow;
        }
        return AppColors.textMutedIncognito;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.nortonYellow.withValues(alpha: 0.35);
        }
        return AppColors.borderIncognito;
      }),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.nortonYellow,
        disabledBackgroundColor: AppColors.disabledYellow,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.disabledTextPrimary,
        side: const BorderSide(
          color: AppColors.borderBlack,
          width: AppSizes.borderThick,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: AppTextStyles.analyzeButton,
      ),
    ),
  );

  static ThemeData resolve({required bool incognito}) =>
      incognito ? AppTheme.incognito : AppTheme.light;
}
