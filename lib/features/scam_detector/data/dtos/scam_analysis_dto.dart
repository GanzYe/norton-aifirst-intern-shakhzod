import 'package:json_annotation/json_annotation.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';

part 'scam_analysis_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ScamAnalysisDto {
  const ScamAnalysisDto({
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
  });

  factory ScamAnalysisDto.fromJson(Map<String, dynamic> json) =>
      _$ScamAnalysisDtoFromJson(json);

  @JsonKey(name: 'risk_level')
  final String riskLevel;
  final int confidence;
  final String explanation;

  ScamAnalysis toEntity() {
    return ScamAnalysis(
      riskLevel: RiskLevel.fromString(riskLevel),
      confidence: confidence.clamp(0, 100),
      explanation: explanation.trim(),
    );
  }
}
