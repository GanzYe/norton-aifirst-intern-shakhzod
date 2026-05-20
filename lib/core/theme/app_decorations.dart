import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

abstract final class AppDecorations {
  static InputDecoration inputField({required String hintText}) {
    final border = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: const BorderSide(
        width: AppSizes.borderMedium,
      ),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint.copyWith(color: AppColors.hintMuted),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: AppSpacing.inputContent,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(
          width: AppSizes.borderThick,
        ),
      ),
    );
  }

  static InputDecoration inlineInputField({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint.copyWith(color: AppColors.hintMuted),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  static BoxDecoration messageField({
    required bool incognito,
    required bool focused,
  }) {
    return BoxDecoration(
      color: AppColors.resolveSurface(incognito: incognito),
      borderRadius: AppRadius.inputFieldAll,
      border: Border.all(
        color: AppColors.resolveBorder(incognito: incognito),
        width: focused ? AppSizes.borderThick : AppSizes.borderMedium,
      ),
    );
  }

  static BoxDecoration loaderField({required bool incognito}) {
    return BoxDecoration(
      color: AppColors.resolveSurface(incognito: incognito),
      borderRadius: AppRadius.inputFieldAll,
      border: Border.all(
        color: AppColors.resolveBorder(incognito: incognito),
        width: AppSizes.borderMedium,
      ),
    );
  }

  static BoxDecoration exampleChip({
    required bool incognito,
    required bool selected,
  }) {
    return BoxDecoration(
      color: selected
          ? AppColors.nortonYellow.withValues(
              alpha: incognito ? 0.22 : AppColors.opacityRiskFill,
            )
          : AppColors.resolveSurfaceElevated(incognito: incognito),
      borderRadius: AppRadius.pillAll,
      border: Border.all(
        color: selected
            ? AppColors.nortonYellow
            : AppColors.resolveBorder(incognito: incognito),
      ),
    );
  }

  static BoxDecoration exampleTile({required Color borderColor}) {
    return BoxDecoration(
      borderRadius: AppRadius.smAll,
      border: Border.all(color: borderColor),
    );
  }

  static BoxDecoration riskBadge({required Color color}) {
    return BoxDecoration(
      color: color.withValues(alpha: AppColors.opacityRiskFill),
      borderRadius: AppRadius.pillAll,
      border: Border.all(color: color, width: AppSizes.borderMedium),
    );
  }
}
