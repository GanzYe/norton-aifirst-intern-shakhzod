import 'package:dio/dio.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';

class UrlScanRepositoryImpl implements UrlScanRepository {
  UrlScanRepositoryImpl(this._dio);

  final Dio _dio;

  static const _visibility = 'unlisted';

  @override
  Future<UrlScanResult> submitUrl(String url) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/scan',
        data: {
          'url': url,
          'visibility': _visibility,
        },
      );

      final status = response.statusCode;
      if (status == null || status < 200 || status >= 300) {
        throw UrlScanRepositoryException(
          'URLScan submission failed with status $status.',
          statusCode: status,
        );
      }

      final scanId = response.data?['uuid'] as String? ??
          response.data?['result'] as String?;

      if (scanId == null || scanId.isEmpty) {
        throw const UrlScanRepositoryException(
          'URLScan response missing scan id.',
        );
      }

      return UrlScanResult(
        url: url,
        scanId: scanId,
        visibility: _visibility,
      );
    } on DioException catch (e) {
      throw UrlScanRepositoryException(
        e.message ?? 'URLScan network error.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
