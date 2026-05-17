// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scam_analysis_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScamAnalysisDto _$ScamAnalysisDtoFromJson(Map<String, dynamic> json) =>
    ScamAnalysisDto(
      riskLevel: json['risk_level'] as String,
      confidence: (json['confidence'] as num).toInt(),
      explanation: json['explanation'] as String,
    );

Map<String, dynamic> _$ScamAnalysisDtoToJson(ScamAnalysisDto instance) =>
    <String, dynamic>{
      'risk_level': instance.riskLevel,
      'confidence': instance.confidence,
      'explanation': instance.explanation,
    };
