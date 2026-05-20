import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/abuse_ipdb_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AbuseIpdbRepositoryImpl repository;

  const testIp = '198.51.100.42';

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.abuseipdb.com/api/v2'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repository = AbuseIpdbRepositoryImpl(dio);
  });

  group('AbuseIpdbRepositoryImpl — happy path', () {
    test('maps confidence and report count into AbuseIpdbResult', () async {
      adapter.onGet(
        '/check',
        (server) => server.reply(200, {
          'data': {
            'ipAddress': testIp,
            'abuseConfidenceScore': 87,
            'totalReports': 41,
            'isPublic': true,
            'countryCode': 'NL',
          },
        }),
        queryParameters: {'ipAddress': testIp, 'maxAgeInDays': 90},
      );

      final result = await repository.checkIp(testIp);

      expect(result.ipAddress, testIp);
      expect(result.abuseConfidenceScore, 87);
      expect(result.totalReports, 41);
    });

    test('clean IP returns zeros without throwing', () async {
      adapter.onGet(
        '/check',
        (server) => server.reply(200, {
          'data': {
            'ipAddress': testIp,
            'abuseConfidenceScore': 0,
            'totalReports': 0,
          },
        }),
        queryParameters: {'ipAddress': testIp, 'maxAgeInDays': 90},
      );

      final result = await repository.checkIp(testIp);

      expect(result.abuseConfidenceScore, 0);
      expect(result.totalReports, 0);
    });
  });

  group('AbuseIpdbRepositoryImpl — error handling', () {
    test('throws when payload has no "data" field', () async {
      adapter.onGet(
        '/check',
        (server) => server.reply(200, {'errors': []}),
        queryParameters: {'ipAddress': testIp, 'maxAgeInDays': 90},
      );

      expect(
        () => repository.checkIp(testIp),
        throwsA(isA<AbuseIpdbRepositoryException>()),
      );
    });

    test('maps DioException (429) to AbuseIpdbRepositoryException', () async {
      adapter.onGet(
        '/check',
        (server) => server.throws(
          429,
          DioException(
            requestOptions: RequestOptions(path: '/check'),
            response: Response(
              requestOptions: RequestOptions(path: '/check'),
              statusCode: 429,
              data: {'errors': []},
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
        queryParameters: {'ipAddress': testIp, 'maxAgeInDays': 90},
      );

      expect(
        () => repository.checkIp(testIp),
        throwsA(
          isA<AbuseIpdbRepositoryException>().having(
            (e) => e.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
    });

    test('429 status response throws with status code propagated', () async {
      adapter.onGet(
        '/check',
        (server) => server.reply(429, {
          'errors': [
            {'detail': 'Too many requests'},
          ],
        }),
        queryParameters: {'ipAddress': testIp, 'maxAgeInDays': 90},
      );

      expect(
        () => repository.checkIp(testIp),
        throwsA(
          isA<AbuseIpdbRepositoryException>().having(
            (e) => e.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
    });
  });
}
