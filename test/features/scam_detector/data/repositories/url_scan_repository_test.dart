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
    // Mirror the production OsintDioFactory.urlScan() configuration so 4xx
    // responses are surfaced as Response objects (not DioExceptions). This
    // is what lets the repository inspect URLScan's JSON error body and
    // make visibility-downgrade decisions.
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://urlscan.io/api/v1',
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repository = UrlScanRepositoryImpl(dio);
  });

  group('UrlScanRepositoryImpl — happy path', () {
    test('extracts uuid into UrlScanResult (unlisted tier)', () async {
      adapter.onPost(
        '/scan/',
        (server) => server.reply(200, {
          'message': 'Submission successful',
          'uuid': 'b6f7d4a0-1111-2222-3333-444455556666',
          'visibility': 'unlisted',
        }),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      final result = await repository.submitUrl(testUrl);

      expect(result.url, testUrl);
      expect(result.scanId, 'b6f7d4a0-1111-2222-3333-444455556666');
      expect(result.visibility, 'unlisted');
    });

    test('falls back to "result" field when "uuid" is absent', () async {
      adapter.onPost(
        '/scan/',
        (server) => server.reply(200, {
          'result': 'https://urlscan.io/result/legacy-id-123/',
        }),
        data: {'url': testUrl, 'visibility': 'unlisted'},
      );

      final result = await repository.submitUrl(testUrl);
      expect(result.scanId, isNotEmpty);
    });

    test(
      'downgrades to public visibility when unlisted is rejected on free tier',
      () async {
        adapter
          ..onPost(
            '/scan/',
            (server) => server.reply(400, {
              'message': 'Visibility unlisted is not allowed',
              'description': 'Your account does not support this tier',
            }),
            data: {'url': testUrl, 'visibility': 'unlisted'},
          )
          ..onPost(
            '/scan/',
            (server) => server.reply(200, {
              'uuid': 'public-tier-uuid',
              'visibility': 'public',
            }),
            data: {'url': testUrl, 'visibility': 'public'},
          );

        final result = await repository.submitUrl(testUrl);
        expect(result.scanId, 'public-tier-uuid');
        expect(result.visibility, 'public');
      },
    );
  });

  group('UrlScanRepositoryImpl — error handling', () {
    test('throws when neither uuid nor result is present', () async {
      adapter.onPost(
        '/scan/',
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

    test('maps 401 (missing API key) to UrlScanRepositoryException', () async {
      adapter.onPost(
        '/scan/',
        (server) => server.reply(401, {'message': 'API key missing'}),
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

    test('regression: surfaces server message + description on 400 '
        '(e.g. "DNS Error – Could not resolve domain")', () async {
      adapter
        ..onPost(
          '/scan/',
          (server) => server.reply(400, {
            'message': 'DNS Error',
            'description': 'Could not resolve domain name.',
            'status': 400,
          }),
          data: {'url': testUrl, 'visibility': 'unlisted'},
        )
        // Second submit (after visibility downgrade attempt) — also 400
        // but with the same DNS error message, so the caller surfaces it.
        ..onPost(
          '/scan/',
          (server) => server.reply(400, {
            'message': 'DNS Error',
            'description': 'Could not resolve domain name.',
            'status': 400,
          }),
          data: {'url': testUrl, 'visibility': 'public'},
        );

      expect(
        () => repository.submitUrl(testUrl),
        throwsA(
          isA<UrlScanRepositoryException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                allOf(contains('DNS Error'), contains('Could not resolve')),
              ),
        ),
      );
    });
  });
}
