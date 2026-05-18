import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';

/// Synthesizes scrubbed user input and OSINT context into a single Gemini prompt.
class BuildAugmentedPromptUseCase {
  const BuildAugmentedPromptUseCase();

  String call({
    required String scrubbedInput,
    required ThreatIntelSnapshot intel,
  }) {
    final buffer = StringBuffer()
      ..writeln('Analyze the following content for scam/phishing risk.')
      ..writeln()
      ..writeln('## User content (PII may be redacted)')
      ..writeln(scrubbedInput)
      ..writeln();

    if (intel.osintSkippedDueToIncognito) {
      buffer.writeln('## Threat intelligence');
      buffer.writeln(
        'OSINT lookups were skipped (Incognito mode + plain text input).',
      );
    } else {
      buffer.writeln('## Threat intelligence');

      final vt = intel.virusTotal;
      if (vt != null) {
        buffer.writeln(
          '- VirusTotal (${vt.url}): ${vt.maliciousCount} malicious detections '
          'out of ${vt.totalEngines} engines.',
        );
      }

      final abuse = intel.abuseIpdb;
      if (abuse != null) {
        buffer.writeln(
          '- AbuseIPDB (${abuse.ipAddress}): abuse confidence '
          '${abuse.abuseConfidenceScore}%, total reports ${abuse.totalReports}.',
        );
      }

      final urlScan = intel.urlScan;
      if (urlScan != null) {
        buffer.writeln(
          '- URLScan.io: scan submitted (${urlScan.visibility}), id ${urlScan.scanId}.',
        );
      }
    }

    final auth = intel.emailAuth;
    if (auth != null) {
      buffer
        ..writeln()
        ..writeln('## Email authentication (from EML Authentication-Results)')
        ..writeln('- SPF: ${_label(auth.spf)}')
        ..writeln('- DKIM: ${_label(auth.dkim)}')
        ..writeln('- DMARC: ${_label(auth.dmarc)}');
    }

    buffer.writeln();
    buffer.writeln(
      'Use all context above. Return structured JSON per the configured schema.',
    );

    return buffer.toString();
  }

  String _label(AuthProtocolResult result) => switch (result) {
    AuthProtocolResult.pass => 'PASS',
    AuthProtocolResult.fail => 'FAIL',
    AuthProtocolResult.none => 'NONE',
    AuthProtocolResult.unknown => 'UNKNOWN',
  };
}
