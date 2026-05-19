import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/url_scan_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late UrlScanRepositoryImpl repository;

  const testUrl = 'http://login-update.example.tk/auth';

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://urlscan.io/api/v1'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repository = UrlScanRepositoryImpl(dio);
  });

  group('UrlScanRepositoryImpl — happy path', () {
    test('extracts uuid into UrlScanResult', () async {
      adapter.onPost(
        '/scan',
        (server) => server.reply(
          200,
          {
            'message': 'Submission successful',
            'uuid': 'b6f7d4a0-1111-2222-3333-444455556666',
            'visibility': 'unlisted',
          },
        ),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      final result = await repository.submitUrl(testUrl);

      expect(result.url, testUrl);
      expect(result.scanId, 'b6f7d4a0-1111-2222-3333-444455556666');
      expect(result.visibility, 'unlisted');
    });

    test('falls back to "result" field when "uuid" is absent', () async {
      adapter.onPost(
        '/scan',
        (server) => server.reply(
          200,
          {
            'result': 'https://urlscan.io/result/legacy-id-123/',
          },
        ),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      final result = await repository.submitUrl(testUrl);
      expect(result.scanId, isNotEmpty);
    });
  });

  group('UrlScanRepositoryImpl — error handling', () {
    test('throws when neither uuid nor result is present', () async {
      adapter.onPost(
        '/scan',
        (server) => server.reply(200, {'message': 'ok'}),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      expect(
        () => repository.submitUrl(testUrl),
        throwsA(
          isA<UrlScanRepositoryException>().having(
            (e) => e.message,
            'message',
            contains('scan id'),
          ),
        ),
      );
    });

    test('maps 401 (missing API key) to UrlScanRepositoryException',
        () async {
      adapter.onPost(
        '/scan',
        (server) => server.reply(
          401,
          {'message': 'API key missing'},
        ),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      expect(
        () => repository.submitUrl(testUrl),
        throwsA(
          isA<UrlScanRepositoryException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('4xx status response throws with status code propagated', () async {
      adapter.onPost(
        '/scan',
        (server) => server.reply(
          400,
          {'message': 'invalid url'},
        ),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      expect(
        () => repository.submitUrl(testUrl),
        throwsA(
          isA<UrlScanRepositoryException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });
}
