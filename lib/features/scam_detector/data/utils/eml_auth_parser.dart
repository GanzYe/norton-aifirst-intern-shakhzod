import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';

/// Parses SPF, DKIM, and DMARC from Authentication-Results via regex alignment
/// checks.
abstract final class EmlAuthParser {
  static final _spfPattern = RegExp(
    r'\bspf\s*=\s*(pass|fail|neutral|softfail|permerror|temperror|none)\b',
    caseSensitive: false,
  );

  static final _dkimPattern = RegExp(
    r'\bdkim\s*=\s*(pass|fail|neutral|none|permerror|temperror)\b',
    caseSensitive: false,
  );

  static final _dmarcPattern = RegExp(
    r'\bdmarc\s*=\s*(pass|fail|none)\b',
    caseSensitive: false,
  );

  static EmailAuthAlignment parseAuthenticationResults(String headerValue) {
    return (
      spf: _mapMatch(_spfPattern.firstMatch(headerValue)),
      dkim: _mapMatch(_dkimPattern.firstMatch(headerValue)),
      dmarc: _mapMatch(_dmarcPattern.firstMatch(headerValue)),
    );
  }

  static AuthProtocolResult _mapMatch(RegExpMatch? match) {
    if (match == null) {
      return AuthProtocolResult.unknown;
    }
    final raw = match.group(1)?.toLowerCase();
    return switch (raw) {
      'pass' => AuthProtocolResult.pass,
      'fail' ||
      'permerror' ||
      'temperror' ||
      'softfail' => AuthProtocolResult.fail,
      'none' || 'neutral' => AuthProtocolResult.none,
      _ => AuthProtocolResult.unknown,
    };
  }
}
