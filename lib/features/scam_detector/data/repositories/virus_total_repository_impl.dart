import 'package:dio/dio.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';

class VirusTotalRepositoryImpl implements VirusTotalRepository {
  VirusTotalRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<VirusTotalResult> scanUrl(String url) async {
    try {
      final submitResponse = await _dio.post<Map<String, dynamic>>(
        '/urls',
        data: {'url': url},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final submitStatus = submitResponse.statusCode;
      if (submitStatus == null || submitStatus < 200 || submitStatus >= 300) {
        throw VirusTotalRepositoryException(
          _messageFromBody(submitResponse.data, 'URL submission failed.'),
          statusCode: submitStatus,
        );
      }

      final analysisId = _extractAnalysisId(submitResponse.data);
      if (analysisId == null || analysisId.isEmpty) {
        throw const VirusTotalRepositoryException(
          'VirusTotal response missing analysis id.',
        );
      }

      final reportResponse = await _dio.get<Map<String, dynamic>>(
        '/urls/$analysisId',
      );

      final reportStatus = reportResponse.statusCode;
      if (reportStatus == null || reportStatus < 200 || reportStatus >= 300) {
        throw VirusTotalRepositoryException(
          _messageFromBody(reportResponse.data, 'URL report fetch failed.'),
          statusCode: reportStatus,
        );
      }

      final stats = reportResponse.data?['data']?['attributes']?['last_analysis_stats']
          as Map<String, dynamic>?;

      final malicious = (stats?['malicious'] as num?)?.toInt() ?? 0;
      final total = stats?.values
              .whereType<num>()
              .fold<int>(0, (sum, value) => sum + value.toInt()) ??
          0;

      return VirusTotalResult(
        url: url,
        maliciousCount: malicious,
        totalEngines: total,
      );
    } on DioException catch (e) {
      throw VirusTotalRepositoryException(
        e.message ?? 'VirusTotal network error.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String? _extractAnalysisId(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final id = data['id'] as String?;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final link = data['links']?['self'] as String?;
    if (link == null) {
      return null;
    }
    final segments = Uri.parse(link).pathSegments;
    return segments.isNotEmpty ? segments.last : null;
  }

  String _messageFromBody(Map<String, dynamic>? body, String fallback) {
    final error = body?['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}
