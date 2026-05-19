import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';

class GeminiRemoteDataSource {
  GeminiRemoteDataSource(this._model);

  static const _stage = 'GEMINI';

  final GenerativeModel _model;

  Future<ScamAnalysisDto> analyzeMessage(String message) =>
      _generateAnalysis(
        Content.text(
          'Analyze this message for scam/phishing risk:\n\n$message',
        ),
        promptChars: message.length,
      );

  /// Accepts a fully-built SOAR master prompt (OSINT + scrubbed input).
  Future<ScamAnalysisDto> analyzeAugmentedContent(String masterPrompt) =>
      _generateAnalysis(
        Content.text(masterPrompt),
        promptChars: masterPrompt.length,
      );

  Future<ScamAnalysisDto> _generateAnalysis(
    Content content, {
    required int promptChars,
  }) async {
    PipelineLog.start(_stage, context: {'promptChars': promptChars});
    try {
      final response = await _model.generateContent([content]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        const exc = GeminiDataSourceException('Empty response from AI model.');
        PipelineLog.failure(_stage, exc);
        throw exc;
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }

      final dto = ScamAnalysisDto.fromJson(decoded);
      PipelineLog.done(
        _stage,
        message: 'verdict received',
        context: {
          'riskLevel': dto.riskLevel,
          'confidence': dto.confidence,
        },
      );
      return dto;
    } on GenerativeAIException catch (e, stack) {
      if (e is InvalidApiKey) {
        const exc = GeminiDataSourceException(
          'Invalid API key. Check GEMINI_API_KEY in your .env file.',
        );
        PipelineLog.failure(_stage, exc, stackTrace: stack);
        throw exc;
      }
      final exc = GeminiDataSourceException(e.message);
      PipelineLog.failure(_stage, exc, stackTrace: stack);
      throw exc;
    } on FormatException catch (e) {
      final exc = GeminiDataSourceException(
        'Could not parse AI response: ${e.message}',
      );
      PipelineLog.failure(_stage, exc);
      throw exc;
    }
  }
}

class GeminiDataSourceException implements Exception {
  const GeminiDataSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
