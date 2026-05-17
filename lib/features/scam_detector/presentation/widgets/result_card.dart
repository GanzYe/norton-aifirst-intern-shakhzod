import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/confidence_bar.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/risk_badge.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.analysis});

  final ScamAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderBlack, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Analysis Result',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                RiskBadge(riskLevel: analysis.riskLevel),
              ],
            ),
            const SizedBox(height: 20),
            ConfidenceBar(
              confidence: analysis.confidence,
              riskLevel: analysis.riskLevel,
            ),
            const SizedBox(height: 20),
            Text(
              analysis.explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
