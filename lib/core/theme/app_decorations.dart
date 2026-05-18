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
        color: AppColors.borderBlack,
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
          color: AppColors.borderBlack,
          width: AppSizes.borderThick,
        ),
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
