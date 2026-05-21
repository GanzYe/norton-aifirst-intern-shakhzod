import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';

/// On-device scam verdict (offline or cloud-fallback path).
abstract interface class LocalAnalysisRepository {
  Future<ScamAnalysis> analyze(String message);
}
