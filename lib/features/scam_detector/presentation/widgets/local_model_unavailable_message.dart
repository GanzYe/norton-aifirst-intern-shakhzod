import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

/// Blocking message when offline and the local model is not available (Case B).
class LocalModelUnavailableMessage extends StatelessWidget {
  const LocalModelUnavailableMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: AppRadius.mdAll,
        border: const Border(
          left: BorderSide(
            color: AppColors.dangerousRed,
            width: AppSizes.borderThick,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Analysis unavailable',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionLabel.copyWith(
              color: AppColors.dangerousRed,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "No internet connection and the local model hasn't been "
            'downloaded yet. Please connect to the internet to analyze this '
            'message.',
            textAlign: TextAlign.center,
            style: AppTextStyles.homeSubtitle,
          ),
        ],
      ),
    );
  }
}
