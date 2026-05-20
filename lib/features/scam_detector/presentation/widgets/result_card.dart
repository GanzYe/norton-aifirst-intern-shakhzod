import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/confidence_bar.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/risk_badge.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({required this.analysis, super.key});

  final ScamAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Analysis Result',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const Spacer(),
                RiskBadge(riskLevel: analysis.riskLevel),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ConfidenceBar(
              confidence: analysis.confidence,
              riskLevel: analysis.riskLevel,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              analysis.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
