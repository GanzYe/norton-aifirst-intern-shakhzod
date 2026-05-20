import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    required this.confidence, required this.riskLevel, super.key,
  });

  final int confidence;
  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confidence: $confidence%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: AppTextStyles.confidenceLabel.fontWeight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.xsAll,
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: AppSizes.confidenceBarHeight,
            backgroundColor: riskLevel.color.withValues(
              alpha: AppColors.opacityRiskTrack,
            ),
            color: riskLevel.color,
          ),
        ),
      ],
    );
  }
}
