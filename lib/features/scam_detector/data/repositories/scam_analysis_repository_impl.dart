import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/cloud_analysis_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';

/// Cloud cascade: Groq (`llama-3.3-70b-versatile`) is tried first because
/// it has a generous free tier. When Groq is rate-limited or otherwise
/// unavailable we fall through to Gemini. Local llama is the final fallback,
/// handled at the use-case layer.
class ScamAnalysisRepositoryImpl implements ScamAnalysisRepository {
  const ScamAnalysisRepositoryImpl({
    required GroqRemoteDataSource groqRemoteDataSource,
    required GeminiRemoteDataSource geminiRemoteDataSource,
  }) : _groq = groqRemoteDataSource,
       _gemini = geminiRemoteDataSource;

  static const _stage = 'CLOUD_CASCADE';

  final GroqRemoteDataSource _groq;
  final GeminiRemoteDataSource _gemini;

  @override
  Future<ScamAnalysis> analyzeMessage(String message) {
    return _runCascade(
      groqCall: () => _groq.analyzeMessage(message),
      geminiCall: () => _gemini.analyzeMessage(message),
    );
  }

  @override
  Future<ScamAnalysis> analyzeAugmentedPrompt(String masterPrompt) {
    return _runCascade(
      groqCall: () => _groq.analyzeAugmentedContent(masterPrompt),
      geminiCall: () => _gemini.analyzeAugmentedContent(masterPrompt),
    );
  }

  Future<ScamAnalysis> _runCascade({
    required Future<ScamAnalysisDto> Function() groqCall,
    required Future<ScamAnalysisDto> Function() geminiCall,
  }) async {
    PipelineLog.start(_stage, context: {'groqConfigured': _groq.isConfigured});

    if (_groq.isConfigured) {
      try {
        PipelineLog.info(_stage, 'trying Groq');
        final dto = await groqCall();
        PipelineLog.done(_stage, message: 'served by Groq');
        return dto.toEntity();
      } on GroqDataSourceException catch (e) {
        PipelineLog.warn(
          _stage,
          e.rateLimited
              ? 'Groq quota hit; falling back to Gemini'
              : 'Groq failed; falling back to Gemini',
          context: {'rateLimited': e.rateLimited},
          error: e,
        );
      }
    }
    try {
      PipelineLog.info(_stage, 'trying Gemini');
      final dto = await geminiCall();
      PipelineLog.done(_stage, message: 'served by Gemini');
      return dto.toEntity();
    } on GeminiDataSourceException catch (e) {
      // FIXED: [P1] Map data-layer failure to domain exception
      // for orchestrator.
      throw CloudAnalysisExhaustedException(e.message);
    } catch (e) {
      throw CloudAnalysisExhaustedException(e.toString());
    }
  }
}
