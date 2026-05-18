import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';

class InputClassifier {
  InputClassifier._();

  static final _urlPattern = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  static final _ipv4Pattern = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d{1,2})\.){3}'
    r'(?:25[0-5]|2[0-4]\d|[01]?\d{1,2})\b',
  );

  static final _emlHeaderPattern = RegExp(
    r'^(?:From|Return-Path|Received|MIME-Version|Content-Type):',
    multiLine: true,
    caseSensitive: false,
  );

  static SoarInputKind classify(String input) {
    final trimmed = input.trim();
    if (_emlHeaderPattern.hasMatch(trimmed)) {
      return SoarInputKind.eml;
    }
    if (_urlPattern.hasMatch(trimmed) &&
        trimmed.split(RegExp(r'\s+')).length <= 3) {
      return SoarInputKind.url;
    }
    if (_ipv4Pattern.hasMatch(trimmed) &&
        trimmed.replaceAll(_ipv4Pattern, '').trim().isEmpty) {
      return SoarInputKind.ipAddress;
    }
    if (_urlPattern.hasMatch(trimmed)) {
      return SoarInputKind.url;
    }
    return SoarInputKind.plainText;
  }
}
