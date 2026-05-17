import 'package:flutter/material.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    super.key,
    required this.confidence,
    required this.riskLevel,
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
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 8,
            backgroundColor: riskLevel.color.withValues(alpha: 0.2),
            color: riskLevel.color,
          ),
        ),
      ],
    );
  }
}
