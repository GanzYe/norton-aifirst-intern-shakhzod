import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/local_analysis_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/local_analysis_repository.dart';

/// Adapts [LocalScamAnalysisService] to the domain [LocalAnalysisRepository].
class LocalAnalysisRepositoryImpl implements LocalAnalysisRepository {
  const LocalAnalysisRepositoryImpl(this._service);

  final LocalScamAnalysisService _service;

  @override
  Future<ScamAnalysis> analyze(String message) async {
    try {
      return await _service.analyze(message);
    } on LocalScamAnalysisException catch (e) {
      throw LocalAnalysisException(e.message);
    }
  }
}
