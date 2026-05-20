import 'package:dio/dio.dart';

/// Builds isolated Dio clients per OSINT vendor with timeouts and API-key
/// interceptors.
abstract final class OsintDioFactory {
  static const _connectTimeout = Duration(seconds: 20);
  static const _receiveTimeout = Duration(seconds: 45);

  static Dio virusTotal({required String apiKey}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://www.virustotal.com/api/v3',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['x-apikey'] = apiKey;
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  static Dio abuseIpdb({required String apiKey}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.abuseipdb.com/api/v2',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Key'] = apiKey;
          options.headers['Accept'] = 'application/json';
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  static Dio urlScan({required String apiKey}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://urlscan.io/api/v1',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {'Content-Type': 'application/json', 'API-Key': apiKey},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    return dio;
  }
}
