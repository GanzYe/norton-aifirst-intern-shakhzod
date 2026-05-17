import 'package:scam_message_detector/features/scam_detector/data/datasources/anthropic_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';

class ScamAnalysisRepositoryImpl implements ScamAnalysisRepository {
  const ScamAnalysisRepositoryImpl(this._remoteDataSource);

  final AnthropicRemoteDataSource _remoteDataSource;

  @override
  Future<ScamAnalysis> analyzeMessage(String message) async {
    try {
      final dto = await _remoteDataSource.analyzeMessage(message);
      return dto.toEntity();
    } on AnthropicDataSourceException {
      rethrow;
    } catch (e) {
      throw AnthropicDataSourceException(e.toString());
    }
  }
}
