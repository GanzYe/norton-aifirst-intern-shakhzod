import 'package:flutter/material.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: riskLevel.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: riskLevel.color, width: 1.5),
      ),
      child: Text(
        riskLevel.label,
        style: TextStyle(
          color: riskLevel.color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
