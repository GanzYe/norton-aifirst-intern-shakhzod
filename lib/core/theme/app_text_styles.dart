import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';

abstract final class AppTextStyles {
  static const TextStyle homeSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    height: AppSizes.subtitleLineHeight,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    color: AppColors.textMuted,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle analyzeButton = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle exampleTile = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle resultCardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle resultBody = TextStyle(
    height: AppSizes.bodyLineHeight,
    color: AppColors.textPrimary,
  );

  static const TextStyle riskBadge = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    letterSpacing: AppSizes.riskBadgeLetterSpacing,
  );

  static const TextStyle confidenceLabel = TextStyle(
    fontWeight: FontWeight.w600,
  );

  static const TextStyle splashTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.nortonYellow,
    height: AppSizes.splashTitleLineHeight,
  );

  static const TextStyle splashAbbrev = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.bold,
    color: AppColors.nortonYellow,
    letterSpacing: AppSizes.splashAbbrevLetterSpacing,
  );

  static const TextStyle splashSubtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textMuted,
    letterSpacing: AppSizes.splashSubtitleLetterSpacing,
  );

  static const TextStyle splashFooter = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle inlineAnalyzeButton = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle inlineEmlButton = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  static const TextStyle loaderTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle loaderSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    height: AppSizes.subtitleLineHeight,
  );

  static const TextStyle loaderPhase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.nortonYellow,
  );

  static const TextStyle exampleChip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Incognito switch secondary line.
  static const TextStyle incognitoTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle incognitoSubtitle = TextStyle(
    fontSize: 11,
    height: AppSizes.subtitleLineHeight,
  );

  // Expandable pipeline log panel.
  static const TextStyle pipelineLogEmpty = TextStyle(fontSize: 12);

  static const TextStyle pipelineLogSummary = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.35,
  );

  static const TextStyle pipelineLogToggle = TextStyle(fontSize: 11);

  static const TextStyle pipelineLogDetail = TextStyle(
    fontFamily: 'monospace',
    fontSize: 10,
    height: 1.4,
  );

  static const TextStyle pipelineLogTag = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}
