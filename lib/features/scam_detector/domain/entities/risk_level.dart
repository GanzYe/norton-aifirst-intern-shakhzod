import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';

enum RiskLevel {
  safe,
  suspicious,
  dangerous;

  String get label => switch (this) {
        RiskLevel.safe => 'SAFE',
        RiskLevel.suspicious => 'SUSPICIOUS',
        RiskLevel.dangerous => 'DANGEROUS',
      };

  Color get color => switch (this) {
        RiskLevel.safe => AppColors.safeGreen,
        RiskLevel.suspicious => AppColors.suspiciousOrange,
        RiskLevel.dangerous => AppColors.dangerousRed,
      };

  static RiskLevel fromString(String value) {
    return switch (value.toUpperCase().trim()) {
      'SAFE' => RiskLevel.safe,
      'SUSPICIOUS' => RiskLevel.suspicious,
      'DANGEROUS' => RiskLevel.dangerous,
      _ => RiskLevel.suspicious,
    };
  }
}
