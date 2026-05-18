import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';

class GeminiRemoteDataSource {
  GeminiRemoteDataSource(this._model);

  final GenerativeModel _model;

  Future<ScamAnalysisDto> analyzeMessage(String message) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Analyze this message for scam/phishing risk:\n\n$message',
        ),
      ]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const GeminiDataSourceException(
          'Empty response from AI model.',
        );
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }

      return ScamAnalysisDto.fromJson(decoded);
    } on GenerativeAIException catch (e, stack) {
      developer.log(
        'Gemini API error',
        name: 'GeminiRemoteDataSource',
        error: e,
        stackTrace: stack,
      );
      if (e is InvalidApiKey) {
        throw const GeminiDataSourceException(
          'Invalid API key. Check GEMINI_API_KEY in your .env file.',
        );
      }
      throw GeminiDataSourceException(e.message);
    } on FormatException catch (e) {
      throw GeminiDataSourceException(
        'Could not parse AI response: ${e.message}',
      );
    }
  }
}

class GeminiDataSourceException implements Exception {
  const GeminiDataSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
