import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:scam_message_detector/core/env/env.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';

class AnthropicRemoteDataSource {
  AnthropicRemoteDataSource(this._dio);

  final Dio _dio;

  static const _model = 'claude-sonnet-4-20250514';
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';

  Future<ScamAnalysisDto> analyzeMessage(String message) async {
    final apiKey = Env.anthropicApiKey;
    if (apiKey.isEmpty || apiKey == 'your_anthropic_api_key_here') {
      throw const AnthropicDataSourceException(
        'Missing API key. Copy .env.example to .env and set ANTHROPIC_API_KEY.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _baseUrl,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        ),
        data: {
          'model': _model,
          'max_tokens': 512,
          'system': _systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content':
                  'Analyze this message for scam/phishing risk:\n\n$message',
            },
          ],
        },
      );

      final content = _extractTextContent(response.data);
      final jsonMap = _parseJsonFromContent(content);
      return ScamAnalysisDto.fromJson(jsonMap);
    } on DioException catch (e, stack) {
      developer.log(
        'Anthropic API error',
        name: 'AnthropicRemoteDataSource',
        error: e,
        stackTrace: stack,
      );
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const AnthropicDataSourceException(
          'Invalid API key. Check ANTHROPIC_API_KEY in your .env file.',
        );
      }
      throw AnthropicDataSourceException(
        e.response?.data?.toString() ?? e.message ?? 'Network request failed.',
      );
    } on FormatException catch (e) {
      throw AnthropicDataSourceException(
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
    final content = data['content'];
    if (content is! List || content.isEmpty) {
      throw const FormatException('No content in response');
    }
    final first = content.first;
    if (first is Map<String, dynamic> && first['text'] is String) {
      return first['text'] as String;
    }
    throw const FormatException('Unexpected content format');
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

class AnthropicDataSourceException implements Exception {
  const AnthropicDataSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
