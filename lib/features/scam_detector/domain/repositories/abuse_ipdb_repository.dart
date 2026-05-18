import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';

abstract interface class AbuseIpdbRepository {
  Future<AbuseIpdbResult> checkIp(String ipAddress);
}

class AbuseIpdbRepositoryException implements Exception {
  const AbuseIpdbRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
