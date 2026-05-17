import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:scam_message_detector/core/env/env.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';

class GeminiRemoteDataSource {
  GeminiRemoteDataSource(this._dio);

  final Dio _dio;

  static const _model = 'gemini-3.1-pro-preview';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<ScamAnalysisDto> analyzeMessage(String message) async {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw const GeminiDataSourceException(
        'Missing API key. Copy .env.example to .env and set GEMINI_API_KEY.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _baseUrl,
        options: Options(
          headers: {
            'x-goog-api-key': apiKey,
          },
        ),
        data: {
          'systemInstruction': {
            'parts': [
              {'text': _systemPrompt},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Analyze this message for scam/phishing risk:\n\n$message',
                },
              ],
            },
          ],
          'generationConfig': {
            'maxOutputTokens': 512,
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          },
        },
      );

      final content = _extractTextContent(response.data);
      final jsonMap = _parseJsonFromContent(content);
      return ScamAnalysisDto.fromJson(jsonMap);
    } on DioException catch (e, stack) {
      developer.log(
        'Gemini API error',
        name: 'GeminiRemoteDataSource',
        error: e,
        stackTrace: stack,
      );
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const GeminiDataSourceException(
          'Invalid API key. Check GEMINI_API_KEY in your .env file.',
        );
      }
      throw GeminiDataSourceException(
        e.response?.data?.toString() ?? e.message ?? 'Network request failed.',
      );
    } on FormatException catch (e) {
      throw GeminiDataSourceException(
        'Could not parse AI response: ${e.message}',
      );
    }
  }

  static const _systemPrompt = '''
You are a cybersecurity expert analyzing messages for scam, phishing, and fraud risk.
Respond with ONLY valid JSON (no markdown, no code fences) using this exact schema:
{
  "risk_level": "SAFE" | "SUSPICIOUS" | "DANGEROUS",
  "confidence": <integer 0-100>,
  "explanation": "<2-3 sentences explaining why>"
}
Rules:
- SAFE: legitimate or low-risk content
- SUSPICIOUS: urgency, impersonation, odd links, or prize/lottery patterns
- DANGEROUS: clear phishing, credential theft, malware links, or financial fraud
''';

  String _extractTextContent(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException('Empty response');
    }
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('No candidates in response');
    }
    final first = candidates.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('Unexpected candidate format');
    }
    final content = first['content'];
    if (content is! Map<String, dynamic>) {
      throw const FormatException('No content in candidate');
    }
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const FormatException('No parts in content');
    }
    final part = parts.first;
    if (part is Map<String, dynamic> && part['text'] is String) {
      return part['text'] as String;
    }
    throw const FormatException('Unexpected part format');
  }

  Map<String, dynamic> _parseJsonFromContent(String content) {
    var trimmed = content.trim();
    if (trimmed.startsWith('```')) {
      trimmed = trimmed.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      trimmed = trimmed.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object');
    }
    return decoded;
  }
}

class GeminiDataSourceException implements Exception {
  const GeminiDataSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
