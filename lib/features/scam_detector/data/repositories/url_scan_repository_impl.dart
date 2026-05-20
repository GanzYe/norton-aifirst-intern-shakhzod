import 'package:dio/dio.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';

class UrlScanRepositoryImpl implements UrlScanRepository {
  UrlScanRepositoryImpl(this._dio);

  static const _stage = 'OSINT.URLScan';

  // URLScan visibility tiers:
  //  - `public`   : free tier, scan and result are publicly listed.
  //  - `unlisted` : not listed publicly but reachable by direct link
  //                 (requires a free urlscan-Pro account).
  //  - `private`  : only visible to the API key owner (paid plan).
  //
  // We try the most privacy-preserving tier the user's key supports and
  // gracefully downgrade if URLScan rejects the request with
  // "Visibility ... not allowed" / similar.
  static const _preferredVisibility = 'unlisted';
  static const _fallbackVisibility = 'public';

  // urlscan.io's canonical submission endpoint requires the trailing slash;
  // calling `/scan` returns a 301 on some deployments that some HTTP clients
  // don't follow on POST (the redirect body is dropped).
  static const _scanPath = '/scan/';

  final Dio _dio;

  @override
  Future<UrlScanResult> submitUrl(String url) async {
    PipelineLog.start(
      _stage,
      context: {'url': url, 'visibility': _preferredVisibility},
    );
    try {
      var result = await _submit(url, _preferredVisibility);
      if (result != null) return result;

      // Visibility was rejected by the server (plan tier doesn't allow it).
      // Retry with the universally-available `public` tier.
      PipelineLog.warn(
        _stage,
        'visibility "$_preferredVisibility" rejected; retrying as '
        '"$_fallbackVisibility"',
      );
      result = await _submit(url, _fallbackVisibility);
      if (result != null) return result;

      const exc = UrlScanRepositoryException('URLScan submission failed.');
      PipelineLog.failure(_stage, exc);
      throw exc;
    } on DioException catch (e, stack) {
      final exc = UrlScanRepositoryException(
        _messageFromBody(e.response?.data) ??
            e.message ??
            'URLScan network error.',
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

  /// Performs a single POST. Returns `null` when the server replied with a
  /// visibility-tier rejection (so the caller can retry with a wider tier),
  /// throws for every other error, returns a [UrlScanResult] on success.
  Future<UrlScanResult?> _submit(String url, String visibility) async {
    PipelineLog.info(
      _stage,
      'POST $_scanPath',
      context: {'visibility': visibility},
    );
    final response = await _dio.post<Map<String, dynamic>>(
      _scanPath,
      data: {'url': url, 'visibility': visibility},
    );

    final status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      final serverMessage =
          _messageFromBody(response.data) ??
          'URLScan submission failed with status $status.';
      if (_looksLikeVisibilityRejection(status, serverMessage) &&
          visibility != _fallbackVisibility) {
        // Signal "retry with public" to the caller.
        return null;
      }
      final exc = UrlScanRepositoryException(serverMessage, statusCode: status);
      PipelineLog.failure(
        _stage,
        exc,
        context: {'status': status, 'visibility': visibility},
      );
      throw exc;
    }

    final scanId =
        response.data?['uuid'] as String? ??
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
      visibility: visibility,
    );
    PipelineLog.done(
      _stage,
      message: 'scan submitted',
      context: {'scanId': scanId, 'visibility': visibility},
    );
    return result;
  }

  /// Pulls the human-readable error out of urlscan's standard error envelope:
  /// `{"message": "...", "description": "...", "status": 400}`.
  String? _messageFromBody(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final message = body['message'] as String?;
    final description = body['description'] as String?;
    if ((message == null || message.isEmpty) &&
        (description == null || description.isEmpty)) {
      return null;
    }
    if (message != null && description != null && description.isNotEmpty) {
      return '$message: $description';
    }
    return message?.isNotEmpty == true ? message : description;
  }

  /// `unlisted` / `private` get rejected on free-tier API keys with messages
  /// like "Visibility unlisted is not allowed for your account". Detect that
  /// shape so we can transparently downgrade to `public`.
  bool _looksLikeVisibilityRejection(int? status, String message) {
    if (status != 400 && status != 403) return false;
    final lower = message.toLowerCase();
    return lower.contains('visibility') ||
        lower.contains('not allowed') ||
        lower.contains('not permitted') ||
        lower.contains('requires');
  }
}
