import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/analysis_pipeline_log_panel.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/confidence_bar.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/risk_badge.dart';

class ResultCard extends StatefulWidget {
  const ResultCard({required this.analysis, super.key});

  final ScamAnalysis analysis;

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  var _logExpanded = false;

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final hasLog = analysis.pipelineLog.isNotEmpty;

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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasLog
                    ? () => setState(() => _logExpanded = !_logExpanded)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.explanation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (hasLog) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              _logExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _logExpanded
                                  ? 'Hide detailed pipeline log'
                                  : 'Tap to view detailed pipeline log',
                              style: AppTextStyles.homeSubtitle.copyWith(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pipeline log',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnalysisPipelineLogPanel(entries: analysis.pipelineLog),
                  ],
                ),
              ),
              crossFadeState: _logExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
