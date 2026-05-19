import 'package:dio/dio.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';

class VirusTotalRepositoryImpl implements VirusTotalRepository {
  VirusTotalRepositoryImpl(this._dio);

  static const _stage = 'OSINT.VT';

  final Dio _dio;

  @override
  Future<VirusTotalResult> scanUrl(String url) async {
    PipelineLog.start(_stage, context: {'url': url});
    try {
      PipelineLog.info(_stage, 'POST /urls (submit for analysis)');
      final submitResponse = await _dio.post<Map<String, dynamic>>(
        '/urls',
        data: {'url': url},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final submitStatus = submitResponse.statusCode;
      if (submitStatus == null || submitStatus < 200 || submitStatus >= 300) {
        final exc = VirusTotalRepositoryException(
          _messageFromBody(submitResponse.data, 'URL submission failed.'),
          statusCode: submitStatus,
        );
        PipelineLog.failure(_stage, exc, context: {'status': submitStatus});
        throw exc;
      }

      final analysisId = _extractAnalysisId(submitResponse.data);
      if (analysisId == null || analysisId.isEmpty) {
        const exc = VirusTotalRepositoryException(
          'VirusTotal response missing analysis id.',
        );
        PipelineLog.failure(_stage, exc);
        throw exc;
      }
      PipelineLog.info(
        _stage,
        'submission accepted, fetching report',
        context: {'analysisId': analysisId},
      );

      final reportResponse = await _dio.get<Map<String, dynamic>>(
        '/urls/$analysisId',
      );

      final reportStatus = reportResponse.statusCode;
      if (reportStatus == null || reportStatus < 200 || reportStatus >= 300) {
        final exc = VirusTotalRepositoryException(
          _messageFromBody(reportResponse.data, 'URL report fetch failed.'),
          statusCode: reportStatus,
        );
        PipelineLog.failure(_stage, exc, context: {'status': reportStatus});
        throw exc;
      }

      final stats = reportResponse.data?['data']?['attributes']?['last_analysis_stats']
          as Map<String, dynamic>?;

      final malicious = (stats?['malicious'] as num?)?.toInt() ?? 0;
      final total = stats?.values
              .whereType<num>()
              .fold<int>(0, (sum, value) => sum + value.toInt()) ??
          0;

      final result = VirusTotalResult(
        url: url,
        maliciousCount: malicious,
        totalEngines: total,
      );
      PipelineLog.done(
        _stage,
        message: 'verdict received',
        context: {
          'malicious': malicious,
          'totalEngines': total,
        },
      );
      return result;
    } on DioException catch (e, stack) {
      final exc = VirusTotalRepositoryException(
        e.message ?? 'VirusTotal network error.',
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
