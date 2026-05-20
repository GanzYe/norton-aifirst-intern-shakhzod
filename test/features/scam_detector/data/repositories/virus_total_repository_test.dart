import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/virus_total_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late VirusTotalRepositoryImpl repository;

  const testUrl = 'https://evil.example/phish';

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://www.virustotal.com/api/v3'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repository = VirusTotalRepositoryImpl(dio);
  });

  group('VirusTotalRepositoryImpl', () {
    test('returns malicious count on successful scan flow', () async {
      adapter
        ..onPost(
          '/urls',
          (server) => server.reply(200, {
            'data': {'id': 'u-test-analysis-id-abc123', 'type': 'analysis'},
          }),
          data: {'url': testUrl},
        )
        // The analysis id returned by POST /urls must be queried against
        // /analyses/{id} and read as `attributes.stats` — querying
        // /urls/{analysis_id} would 400 with "Wrong URL id".
        ..onGet(
          '/analyses/u-test-analysis-id-abc123',
          (server) => server.reply(200, {
            'data': {
              'attributes': {
                'status': 'completed',
                'stats': {
                  'malicious': 5,
                  'suspicious': 1,
                  'harmless': 60,
                  'undetected': 10,
                },
              },
            },
          }),
        );

      final result = await repository.scanUrl(testUrl);

      expect(result.url, testUrl);
      expect(result.maliciousCount, 5);
      expect(result.totalEngines, 76);
    });

    test(
      'regression: uses /analyses/{id} (not /urls/{id}) for analysis lookup',
      () async {
        adapter
          ..onPost(
            '/urls',
            (server) => server.reply(200, {
              'data': {'id': 'u-regression-id', 'type': 'analysis'},
            }),
            data: {'url': testUrl},
          )
          // Simulate the real VT behavior: /urls/{analysis_id} would 400.
          ..onGet(
            '/urls/u-regression-id',
            (server) => server.reply(400, {
              'error': {
                'code': 'WrongUrlIdError',
                'message': 'Wrong URL id: u-regression-id',
              },
            }),
          )
          ..onGet(
            '/analyses/u-regression-id',
            (server) => server.reply(200, {
              'data': {
                'attributes': {
                  'status': 'completed',
                  'stats': {'malicious': 2, 'harmless': 70},
                },
              },
            }),
          );

        final result = await repository.scanUrl(testUrl);

        expect(result.maliciousCount, 2);
        expect(result.totalEngines, 72);
      },
    );

    test(
      'throws VirusTotalRepositoryException on 429 without crashing',
      () async {
        adapter.onPost(
          '/urls',
          (server) => server.reply(429, {
            'error': {
              'code': 'QuotaExceededError',
              'message': 'Too many requests',
            },
          }),
          data: {'url': testUrl},
        );

        expect(
          () => repository.scanUrl(testUrl),
          throwsA(isA<VirusTotalRepositoryException>()),
        );
      },
    );

    test('maps DioException to VirusTotalRepositoryException', () async {
      adapter.onPost(
        '/urls',
        (server) => server.throws(
          429,
          DioException(
            requestOptions: RequestOptions(path: '/urls'),
            response: Response(
              requestOptions: RequestOptions(path: '/urls'),
              statusCode: 429,
              data: {
                'error': {'message': 'Rate limited'},
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      );

      expect(
        () => repository.scanUrl(testUrl),
        throwsA(
          isA<VirusTotalRepositoryException>().having(
            (e) => e.message,
            'message',
            isNotEmpty,
          ),
        ),
      );
    });
  });
}
