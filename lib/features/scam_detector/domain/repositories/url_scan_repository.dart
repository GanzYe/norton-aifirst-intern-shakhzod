import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';

abstract interface class UrlScanRepository {
  Future<UrlScanResult> submitUrl(String url);
}

class UrlScanRepositoryException implements Exception {
  const UrlScanRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
