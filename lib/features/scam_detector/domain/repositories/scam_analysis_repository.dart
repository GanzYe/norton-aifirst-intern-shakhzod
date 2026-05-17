import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';

abstract interface class ScamAnalysisRepository {
  Future<ScamAnalysis> analyzeMessage(String message);
}
