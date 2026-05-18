import 'package:enough_mail/enough_mail.dart';
import 'package:scam_message_detector/features/scam_detector/data/utils/eml_auth_parser.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';

class EmlParseRepositoryImpl implements EmlParseRepository {
  @override
  ParsedEmlContent parse(String rawEml) {
    final message = MimeMessage.parseFromText(rawEml);
    final authHeader = _findAuthenticationResults(message);
    final emailAuth = authHeader != null
        ? EmlAuthParser.parseAuthenticationResults(authHeader)
        : null;

    final bodyText = message.decodeTextPlainPart() ??
        message.decodeTextHtmlPart()?.replaceAll(RegExp(r'<[^>]*>'), ' ') ??
        '';

    return ParsedEmlContent(
      bodyPreview: bodyText.trim().isNotEmpty ? bodyText.trim() : rawEml,
      emailAuth: emailAuth,
    );
  }

  String? _findAuthenticationResults(MimeMessage message) {
    final headers = message.headers;
    if (headers == null) {
      return null;
    }
    for (final header in headers) {
      if (header.name.toLowerCase() == 'authentication-results') {
        return header.value;
      }
    }
    return null;
  }
}
