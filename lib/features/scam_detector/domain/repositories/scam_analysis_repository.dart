import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';

abstract interface class ScamAnalysisRepository {
  Future<ScamAnalysis> analyzeMessage(String message);

  /// Sends a pre-built SOAR master prompt to Gemini (structured JSON unchanged).
  Future<ScamAnalysis> analyzeAugmentedPrompt(String masterPrompt);
}
