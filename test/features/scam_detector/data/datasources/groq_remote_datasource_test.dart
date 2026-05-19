import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late GroqRemoteDataSource ds;

  const apiKey = 'groq-test-key';
  const message = 'Your bank account has been suspended, log in at evil.example to fix.';
  const endpoint = '/openai/v1/chat/completions';

  // http_mock_adapter 0.6.x requires an explicit body matcher for POST routes
  // — `Matchers.any` accepts any JSON payload, which is what we want since
  // GroqRemoteDataSource embeds a private system-prompt string we can't reach
  // from a unit test.
  final anyBody = Matchers.any;

  Map<String, dynamic> _chatPayload(Map<String, dynamic> verdict) {
    return {
      'id': 'chatcmpl-test',
      'object': 'chat.completion',
      'choices': [
        {
          'index': 0,
          'finish_reason': 'stop',
          'message': {
            'role': 'assistant',
            'content': jsonEncode(verdict),
          },
        },
      ],
    };
  }

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.groq.com'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    ds = GroqRemoteDataSource(dio: dio, apiKey: apiKey);
  });

  group('GroqRemoteDataSource — happy path', () {
    test('parses JSON content into a ScamAnalysisDto', () async {
      adapter.onPost(
        endpoint,
        (server) => server.reply(
          200,
          _chatPayload({
            'risk_level': 'DANGEROUS',
            'confidence': 91,
            'explanation': 'Bank suspension wording plus a suspicious .example login link is classic phishing.',
          }),
        ),
        data: anyBody,
      );

      final dto = await ds.analyzeMessage(message);

      expect(dto.riskLevel, 'DANGEROUS');
      expect(dto.confidence, 91);
      expect(dto.explanation, contains('phishing'));
    });

    test('analyzeAugmentedContent forwards the master prompt unchanged',
        () async {
      const masterPrompt = '## User content\n<scrubbed>\n## Threat intelligence\n- VT: 7/76 malicious';

      // Capture the outgoing request body via an interceptor so we can
      // verify the master-prompt round-trip.
      Map<String, dynamic>? capturedBody;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = options.data as Map<String, dynamic>;
            handler.next(options);
          },
        ),
      );

      adapter.onPost(
        endpoint,
        (server) => server.reply(
          200,
          _chatPayload({
            'risk_level': 'SUSPICIOUS',
            'confidence': 70,
            'explanation': 'Mixed OSINT signals warrant caution.',
          }),
        ),
        data: anyBody,
      );

      final dto = await ds.analyzeAugmentedContent(masterPrompt);

      expect(dto.riskLevel, 'SUSPICIOUS');
      expect(capturedBody, isNotNull);
      final messages = capturedBody!['messages'] as List;
      expect(messages.last['content'], masterPrompt);
      expect(capturedBody!['model'], 'llama-3.3-70b-versatile');
      expect(
        capturedBody!['response_format'],
        {'type': 'json_object'},
      );
    });
  });

  group('GroqRemoteDataSource — error handling', () {
    test('flags rate-limit on HTTP 429 (rateLimited=true)', () async {
      adapter.onPost(
        endpoint,
        (server) => server.reply(429, {
          'error': {'message': 'rate_limit_exceeded'},
        }),
        data: anyBody,
      );

      try {
        await ds.analyzeMessage(message);
        fail('Expected GroqDataSourceException');
      } on GroqDataSourceException catch (e) {
        expect(e.rateLimited, isTrue);
      }
    });

    test('flags rate-limit on HTTP 402 (rateLimited=true)', () async {
      adapter.onPost(
        endpoint,
        (server) => server.reply(402, {
          'error': {'message': 'payment_required'},
        }),
        data: anyBody,
      );

      try {
        await ds.analyzeMessage(message);
        fail('Expected GroqDataSourceException');
      } on GroqDataSourceException catch (e) {
        expect(e.rateLimited, isTrue);
      }
    });

    test('5xx server error propagates non-rate-limited exception', () async {
      adapter.onPost(
        endpoint,
        (server) => server.reply(500, {
          'error': {'message': 'internal_error'},
        }),
        data: anyBody,
      );

      try {
        await ds.analyzeMessage(message);
        fail('Expected GroqDataSourceException');
      } on GroqDataSourceException catch (e) {
        expect(e.rateLimited, isFalse);
      }
    });

    test('empty assistant content throws', () async {
      adapter.onPost(
        endpoint,
        (server) => server.reply(200, {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': '   '},
            },
          ],
        }),
        data: anyBody,
      );

      expect(
        () => ds.analyzeMessage(message),
        throwsA(
          isA<GroqDataSourceException>()
              .having((e) => e.message, 'message', contains('Empty')),
        ),
      );
    });

    test('malformed JSON content throws parse-error exception', () async {
      adapter.onPost(
        endpoint,
        (server) => server.reply(200, {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'not-json-at-all',
              },
            },
          ],
        }),
        data: anyBody,
      );

      expect(
        () => ds.analyzeMessage(message),
        throwsA(
          isA<GroqDataSourceException>()
              .having((e) => e.rateLimited, 'rateLimited', isFalse),
        ),
      );
    });

    test('missing API key short-circuits with non-rate-limited exception',
        () async {
      final dsNoKey = GroqRemoteDataSource(dio: dio, apiKey: '');
      expect(dsNoKey.isConfigured, isFalse);
      try {
        await dsNoKey.analyzeMessage(message);
        fail('Expected GroqDataSourceException');
      } on GroqDataSourceException catch (e) {
        expect(e.rateLimited, isFalse);
        expect(e.message, contains('GROQ_API_KEY'));
      }
    });
  });
}
