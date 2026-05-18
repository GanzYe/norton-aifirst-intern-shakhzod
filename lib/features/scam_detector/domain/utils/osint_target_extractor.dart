class OsintTargets {
  const OsintTargets({this.primaryUrl, this.primaryIp});

  final String? primaryUrl;
  final String? primaryIp;
}

class OsintTargetExtractor {
  OsintTargetExtractor._();

  static final _urlPattern = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  static final _ipv4Pattern = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d{1,2})\.){3}'
    r'(?:25[0-5]|2[0-4]\d|[01]?\d{1,2})\b',
  );

  static OsintTargets extract(String input) {
    final urlMatch = _urlPattern.firstMatch(input);
    final ipMatch = _ipv4Pattern.firstMatch(input);
    return OsintTargets(
      primaryUrl: urlMatch?.group(0),
      primaryIp: ipMatch?.group(0),
    );
  }
}
