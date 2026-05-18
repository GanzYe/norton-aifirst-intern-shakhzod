import 'package:dio/dio.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';

class AbuseIpdbRepositoryImpl implements AbuseIpdbRepository {
  AbuseIpdbRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<AbuseIpdbResult> checkIp(String ipAddress) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/check',
        queryParameters: {
          'ipAddress': ipAddress,
          'maxAgeInDays': 90,
        },
      );

      final status = response.statusCode;
      if (status == null || status < 200 || status >= 300) {
        throw AbuseIpdbRepositoryException(
          'AbuseIPDB check failed with status $status.',
          statusCode: status,
        );
      }

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const AbuseIpdbRepositoryException('AbuseIPDB response missing data.');
      }

      return AbuseIpdbResult(
        ipAddress: ipAddress,
        abuseConfidenceScore:
            (data['abuseConfidenceScore'] as num?)?.toInt() ?? 0,
        totalReports: (data['totalReports'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw AbuseIpdbRepositoryException(
        e.message ?? 'AbuseIPDB network error.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
