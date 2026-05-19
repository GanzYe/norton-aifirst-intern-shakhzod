import 'package:dio/dio.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';

class AbuseIpdbRepositoryImpl implements AbuseIpdbRepository {
  AbuseIpdbRepositoryImpl(this._dio);

  static const _stage = 'OSINT.AbuseIPDB';

  final Dio _dio;

  @override
  Future<AbuseIpdbResult> checkIp(String ipAddress) async {
    PipelineLog.start(_stage, context: {'ip': ipAddress, 'maxAgeInDays': 90});
    try {
      PipelineLog.info(_stage, 'GET /check');
      final response = await _dio.get<Map<String, dynamic>>(
        '/check',
        queryParameters: {
          'ipAddress': ipAddress,
          'maxAgeInDays': 90,
        },
      );

      final status = response.statusCode;
      if (status == null || status < 200 || status >= 300) {
        final exc = AbuseIpdbRepositoryException(
          'AbuseIPDB check failed with status $status.',
          statusCode: status,
        );
        PipelineLog.failure(_stage, exc, context: {'status': status});
        throw exc;
      }

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        const exc = AbuseIpdbRepositoryException(
          'AbuseIPDB response missing data.',
        );
        PipelineLog.failure(_stage, exc);
        throw exc;
      }

      final result = AbuseIpdbResult(
        ipAddress: ipAddress,
        abuseConfidenceScore:
            (data['abuseConfidenceScore'] as num?)?.toInt() ?? 0,
        totalReports: (data['totalReports'] as num?)?.toInt() ?? 0,
      );
      PipelineLog.done(
        _stage,
        message: 'reputation check complete',
        context: {
          'abuseConfidence': result.abuseConfidenceScore,
          'totalReports': result.totalReports,
        },
      );
      return result;
    } on DioException catch (e, stack) {
      final exc = AbuseIpdbRepositoryException(
        e.message ?? 'AbuseIPDB network error.',
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
