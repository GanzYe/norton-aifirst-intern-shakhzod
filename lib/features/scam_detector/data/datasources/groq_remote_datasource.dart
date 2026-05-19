import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';

/// Primary cloud analysis path. Uses Groq's OpenAI-compatible Chat
/// Completions API with `llama-3.3-70b-versatile` (free tier; falls back to
/// Gemini once quota is exhausted).
class GroqRemoteDataSource {
  GroqRemoteDataSource({required Dio dio, required String apiKey})
      : _dio = dio,
        _apiKey = apiKey;

  static const _model = 'llama-3.3-70b-versatile';
  static const _systemPrompt = '''
You are a cybersecurity expert analyzing messages for scam, phishing, and fraud risk.
Respond with ONLY a valid JSON object and no other text. Schema:
{"risk_level":"SAFE"|"SUSPICIOUS"|"DANGEROUS","confidence":0-100,"explanation":"two to three sentences"}
Rules:
- SAFE: legitimate or low-risk content
- SUSPICIOUS: urgency, impersonation, odd links, or prize/lottery patterns
- DANGEROUS: clear phishing, credential theft, malware links, or financial fraud
''';

  final Dio _dio;
  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<ScamAnalysisDto> analyzeAugmentedContent(String masterPrompt) {
    return _generate(masterPrompt);
  }

  Future<ScamAnalysisDto> analyzeMessage(String message) {
    return _generate(
      'Analyze this message for scam/phishing risk:\n\n$message',
    );
  }

  Future<ScamAnalysisDto> _generate(String userPrompt) async {
    if (!isConfigured) {
      throw const GroqDataSourceException(
        'Missing GROQ_API_KEY. Skipping Groq path.',
        rateLimited: false,
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'temperature': 0.2,
          'max_tokens': 512,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        },
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 429 || status == 402) {
        throw const GroqDataSourceException(
          'Groq quota exhausted.',
          rateLimited: true,
        );
      }
      if (status >= 400 || data == null) {
        throw GroqDataSourceException(
          'Groq error ($status): ${_extractError(data)}',
          rateLimited: false,
        );
      }

      final text = _extractContent(data);
      if (text == null || text.trim().isEmpty) {
        throw const GroqDataSourceException(
          'Empty response from Groq.',
          rateLimited: false,
        );
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }
      return ScamAnalysisDto.fromJson(decoded);
    } on GroqDataSourceException {
      rethrow;
    } on DioException catch (e, stack) {
      developer.log(
        'Groq API error',
        name: 'GroqRemoteDataSource',
        error: e,
        stackTrace: stack,
      );
      final rateLimited = e.response?.statusCode == 429 ||
          e.response?.statusCode == 402;
      throw GroqDataSourceException(
        e.message ?? 'Groq request failed.',
        rateLimited: rateLimited,
      );
    } on FormatException catch (e) {
      throw GroqDataSourceException(
        'Could not parse Groq response: ${e.message}',
        rateLimited: false,
      );
    }
  }

  String? _extractContent(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  String _extractError(Object? data) {
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        final msg = err['message'];
        if (msg is String) return msg;
      }
    }
    return 'unknown error';
  }
}

class GroqDataSourceException implements Exception {
  const GroqDataSourceException(this.message, {required this.rateLimited});

  final String message;

  /// True when the failure looks like a quota/rate-limit hit and the caller
  /// should fall through to the secondary cloud provider.
  final bool rateLimited;

  @override
  String toString() => message;
}
