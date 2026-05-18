import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';

part 'threat_intel_snapshot.freezed.dart';

@freezed
abstract class ThreatIntelSnapshot with _$ThreatIntelSnapshot {
  const factory ThreatIntelSnapshot({
    VirusTotalResult? virusTotal,
    AbuseIpdbResult? abuseIpdb,
    UrlScanResult? urlScan,
    EmailAuthAlignment? emailAuth,
    @Default(false) bool osintSkippedDueToIncognito,
  }) = _ThreatIntelSnapshot;
}

@freezed
abstract class VirusTotalResult with _$VirusTotalResult {
  const factory VirusTotalResult({
    required String url,
    required int maliciousCount,
    required int totalEngines,
  }) = _VirusTotalResult;
}

@freezed
abstract class AbuseIpdbResult with _$AbuseIpdbResult {
  const factory AbuseIpdbResult({
    required String ipAddress,
    required int abuseConfidenceScore,
    required int totalReports,
  }) = _AbuseIpdbResult;
}

@freezed
abstract class UrlScanResult with _$UrlScanResult {
  const factory UrlScanResult({
    required String url,
    required String scanId,
    required String visibility,
  }) = _UrlScanResult;
}
