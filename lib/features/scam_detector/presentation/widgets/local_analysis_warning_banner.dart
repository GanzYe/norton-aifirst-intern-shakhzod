import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

/// Non-blocking warning when a result was produced offline on-device (Case A).
class LocalAnalysisWarningBanner extends StatelessWidget {
  const LocalAnalysisWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: AppRadius.mdAll,
        border: const Border(
          left: BorderSide(
            color: AppColors.nortonYellow,
            width: AppSizes.borderThick,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: AppSizes.iconExample,
            color: AppColors.suspiciousOrange,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local analysis only',
                  style: AppTextStyles.sectionLabel,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'No internet connection. This result was generated on-device '
                  'and may be less accurate. Connect to the internet for full '
                  'analysis.',
                  style: AppTextStyles.homeSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
