import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';

abstract interface class VirusTotalRepository {
  Future<VirusTotalResult> scanUrl(String url);
}

class VirusTotalRepositoryException implements Exception {
  const VirusTotalRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
