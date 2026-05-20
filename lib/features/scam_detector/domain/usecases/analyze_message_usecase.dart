import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';

class AnalyzeMessageUseCase {
  const AnalyzeMessageUseCase(this._repository);

  final ScamAnalysisRepository _repository;

  Future<ScamAnalysis> call(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const AnalyzeMessageException('Please enter a message to analyze.');
    }
    if (trimmed.length < 3) {
      throw const AnalyzeMessageException(
        'Message is too short. Provide more context for analysis.',
      );
    }
    return _repository.analyzeMessage(trimmed);
  }
}

class AnalyzeMessageException implements Exception {
  const AnalyzeMessageException(this.message);

  final String message;

  @override
  String toString() => message;
}
