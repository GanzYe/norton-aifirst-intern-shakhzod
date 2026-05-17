import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';

part 'scam_analysis.freezed.dart';

@freezed
abstract class ScamAnalysis with _$ScamAnalysis {
  const factory ScamAnalysis({
    required RiskLevel riskLevel,
    required int confidence,
    required String explanation,
  }) = _ScamAnalysis;
}
