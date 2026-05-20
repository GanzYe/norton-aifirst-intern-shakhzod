import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.riskLevel, super.key});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.riskBadge,
      decoration: AppDecorations.riskBadge(color: riskLevel.color),
      child: Text(
        riskLevel.label,
        style: AppTextStyles.riskBadge.copyWith(color: riskLevel.color),
      ),
    );
  }
}
