import 'dart:developer' as developer;

import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';

/// Cloud cascade: Groq (`llama-3.3-70b-versatile`) is tried first because
/// it has a generous free tier. When Groq is rate-limited or otherwise
/// unavailable we fall through to Gemini. Local llama is the final fallback,
/// handled at the use-case layer.
class ScamAnalysisRepositoryImpl implements ScamAnalysisRepository {
  const ScamAnalysisRepositoryImpl({
    required GroqRemoteDataSource groqRemoteDataSource,
    required GeminiRemoteDataSource geminiRemoteDataSource,
  })  : _groq = groqRemoteDataSource,
        _gemini = geminiRemoteDataSource;

  final GroqRemoteDataSource _groq;
  final GeminiRemoteDataSource _gemini;

  @override
  Future<ScamAnalysis> analyzeMessage(String message) async {
    if (_groq.isConfigured) {
      try {
        final dto = await _groq.analyzeMessage(message);
        return dto.toEntity();
      } on GroqDataSourceException catch (e) {
        _logGroqFallthrough(e);
      }
    }
    try {
      final dto = await _gemini.analyzeMessage(message);
      return dto.toEntity();
    } on GeminiDataSourceException {
      rethrow;
    } catch (e) {
      throw GeminiDataSourceException(e.toString());
    }
  }

  @override
  Future<ScamAnalysis> analyzeAugmentedPrompt(String masterPrompt) async {
    if (_groq.isConfigured) {
      try {
        final dto = await _groq.analyzeAugmentedContent(masterPrompt);
        return dto.toEntity();
      } on GroqDataSourceException catch (e) {
        _logGroqFallthrough(e);
      }
    }
    try {
      final dto = await _gemini.analyzeAugmentedContent(masterPrompt);
      return dto.toEntity();
    } on GeminiDataSourceException {
      rethrow;
    } catch (e) {
      throw GeminiDataSourceException(e.toString());
    }
  }

  void _logGroqFallthrough(GroqDataSourceException e) {
    developer.log(
      e.rateLimited
          ? 'Groq quota hit; falling back to Gemini.'
          : 'Groq failed; falling back to Gemini.',
      name: 'ScamAnalysisRepositoryImpl',
      error: e,
    );
  }
}
