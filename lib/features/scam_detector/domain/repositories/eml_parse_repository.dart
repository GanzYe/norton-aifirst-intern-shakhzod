import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';

class ParsedEmlContent {
  const ParsedEmlContent({required this.bodyPreview, this.emailAuth});

  final String bodyPreview;
  final EmailAuthAlignment? emailAuth;
}

abstract interface class EmlParseRepository {
  ParsedEmlContent parse(String rawEml);
}
