import 'package:dio/dio.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';

class UrlScanRepositoryImpl implements UrlScanRepository {
  UrlScanRepositoryImpl(this._dio);

  static const _stage = 'OSINT.URLScan';
  static const _visibility = 'unlisted';

  final Dio _dio;

  @override
  Future<UrlScanResult> submitUrl(String url) async {
    PipelineLog.start(
      _stage,
      context: {'url': url, 'visibility': _visibility},
    );
    try {
      PipelineLog.info(_stage, 'POST /scan');
      final response = await _dio.post<Map<String, dynamic>>(
        '/scan',
        data: {
          'url': url,
          'visibility': _visibility,
        },
      );

      final status = response.statusCode;
      if (status == null || status < 200 || status >= 300) {
        final exc = UrlScanRepositoryException(
          'URLScan submission failed with status $status.',
          statusCode: status,
        );
        PipelineLog.failure(_stage, exc, context: {'status': status});
        throw exc;
      }

      final scanId = response.data?['uuid'] as String? ??
          response.data?['result'] as String?;

      if (scanId == null || scanId.isEmpty) {
        const exc = UrlScanRepositoryException(
          'URLScan response missing scan id.',
        );
        PipelineLog.failure(_stage, exc);
        throw exc;
      }

      final result = UrlScanResult(
        url: url,
        scanId: scanId,
        visibility: _visibility,
      );
      PipelineLog.done(
        _stage,
        message: 'scan submitted',
        context: {'scanId': scanId},
      );
      return result;
    } on DioException catch (e, stack) {
      final exc = UrlScanRepositoryException(
        e.message ?? 'URLScan network error.',
        statusCode: e.response?.statusCode,
      );
      PipelineLog.failure(
        _stage,
        exc,
        stackTrace: stack,
        context: {'status': e.response?.statusCode},
      );
      throw exc;
    }
  }
}
