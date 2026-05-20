/// Deterministic PII masking: structured patterns + leak sweeps.
abstract final class PiiRegexScrubber {
  static String scrub(String input) {
    var text = input;
    for (var pass = 0; pass < 4; pass++) {
      final next = _scrubPass(text);
      if (next == text) break;
      text = next;
    }
    return text;
  }

  static bool containsDetectablePii(String text) {
    if (_email.hasMatch(text)) return true;
    if (_phone.hasMatch(text)) return true;
    if (_ssn.hasMatch(text)) return true;
    if (_card.hasMatch(text)) return true;
    if (_greetingName.hasMatch(text)) return true;
    for (final m in _selfIdentityName.allMatches(text)) {
      if (!_isAllowlistedNamePhrase(m.group(2)!)) return true;
    }
    for (final m in _bareIsName.allMatches(text)) {
      if (!_isAllowlistedNamePhrase(m.group(2)!)) return true;
    }
    if (_roleName.hasMatch(text)) return true;
    if (_titleName.hasMatch(text)) return true;
    if (_hasUnredactedSecretMatch(text)) return true;
    for (final m in _capitalizedToken.allMatches(text)) {
      final word = m.group(0)!;
      if (_isAlreadyRedacted(word)) continue;
      if (word.length < 3 || word.length > 16) continue;
      if (_capitalizedAllowlist.contains(word.toLowerCase())) continue;
      return true;
    }
    return false;
  }

  static String _scrubPass(String input) {
    var text = input;

    text = _replaceAllMapped(text, _email, (_) => '[REDACTED_EMAIL]');
    text = _replaceAllMapped(text, _phone, (_) => '[REDACTED_PHONE]');
    text = _replaceAllMapped(text, _ssn, (_) => '[REDACTED_SSN]');
    text = _replaceAllMapped(text, _card, (_) => '[REDACTED_CARD]');

    text = _replaceAllMapped(text, _greetingName, (m) {
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _nameTypoFragment, (m) {
      final parts = m.group(0)!.split(RegExp(r'\s+'));
      if (parts.length < 2) return m.group(0)!;
      if (_typoSecondWordStop.contains(parts.last.toLowerCase())) {
        return m.group(0)!;
      }
      return '[REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _selfIdentityName, (m) {
      if (_isAllowlistedNamePhrase(m.group(2)!)) return m.group(0)!;
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _bareIsName, (m) {
      if (_isAllowlistedNamePhrase(m.group(2)!)) return m.group(0)!;
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _titleName, (m) {
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _roleName, (m) {
      final prefix = m.group(1) ?? '';
      final role = m.group(2)!;
      return '$prefix$role [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _labeledSecret, (m) {
      if (_isRedactedPlaceholder(m.group(2)!)) return m.group(0)!;
      return '${m.group(1)} [REDACTED_SECRET]';
    });

    text = _replaceAllMapped(text, _unlabeledApiKey, (m) {
      if (_isRedactedPlaceholder(m.group(2)!)) return m.group(0)!;
      return '${m.group(1)} [REDACTED_SECRET]';
    });

    text = _replaceAllMapped(text, _skPrefix, (_) => '[REDACTED_SECRET]');

    text = _replaceAllMapped(text, _highEntropyToken, (m) {
      final token = m.group(0)!;
      if (_isAlreadyRedacted(token)) return token;
      return '[REDACTED_SECRET]';
    });

    text = _sweepRepeatedNames(text);
    text = _sweepUnknownCapitalizedNames(text);
    return _stripOrphanTypoTails(text);
  }

  static bool _hasUnredactedSecretMatch(String text) {
    for (final m in _labeledSecret.allMatches(text)) {
      if (!_isRedactedPlaceholder(m.group(2)!)) return true;
    }
    for (final m in _unlabeledApiKey.allMatches(text)) {
      if (!_isRedactedPlaceholder(m.group(2)!)) return true;
    }
    if (_skPrefix.hasMatch(text)) return true;
    for (final m in _highEntropyToken.allMatches(text)) {
      if (!_isRedactedPlaceholder(m.group(0)!)) return true;
    }
    return false;
  }

  /// Removes stray initials left after scrubbing (e.g. redacted name + " l.").
  static String _stripOrphanTypoTails(String text) {
    return text.replaceAll(
      RegExp(r'\[REDACTED_NAME\]\s+[a-z]{1,2}\b'),
      '[REDACTED_NAME]',
    );
  }

  static bool _isAllowlistedNamePhrase(String phrase) {
    return phrase
        .split(RegExp(r'\s+'))
        .every((w) => _capitalizedAllowlist.contains(w.toLowerCase()));
  }

  /// Catches leftover person names (e.g. after a partial LLM scrub).
  static String _sweepUnknownCapitalizedNames(String text) {
    return text.replaceAllMapped(_capitalizedToken, (m) {
      final word = m.group(0)!;
      if (_isAlreadyRedacted(word)) return word;
      if (word.length < 3 || word.length > 16) return word;
      if (_capitalizedAllowlist.contains(word.toLowerCase())) return word;
      return '[REDACTED_NAME]';
    });
  }

  static bool _isLikelyLeakedName(String word) {
    if (_isAlreadyRedacted(word)) return false;
    if (_capitalizedAllowlist.contains(word.toLowerCase())) return false;
    if (word.length < 3 || word.length > 16) return false;
    return true;
  }

  static String _sweepRepeatedNames(String text) {
    final counts = <String, int>{};
    for (final m in _capitalizedToken.allMatches(text)) {
      final word = m.group(0)!;
      if (!_isLikelyLeakedName(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }

    var out = text;
    for (final word in counts.keys) {
      if (counts[word]! < 2) continue;
      out = out.replaceAll(
        RegExp('\\b${RegExp.escape(word)}\\b'),
        '[REDACTED_NAME]',
      );
    }
    return out;
  }

  static String _replaceAllMapped(
    String input,
    RegExp pattern,
    String Function(Match) convert,
  ) {
    return input.replaceAllMapped(pattern, convert);
  }

  static bool _isAlreadyRedacted(String token) =>
      token.toUpperCase().contains('REDACTED');

  static bool _isRedactedPlaceholder(String value) =>
      _isAlreadyRedacted(value) || value.startsWith('[');

  static final _email = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final _phone = RegExp(
    r'\b(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{2,4}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}\b',
  );

  static final _ssn = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');

  static final _card = RegExp(r'\b(?:\d{4}[-\s]?){3}\d{4}\b');

  static final _greetingName = RegExp(
    r'\b(hello|hi|hey|dear|greetings)\s+([A-Z][a-z]+)\b',
    caseSensitive: false,
  );

  static final _selfIdentityName = RegExp(
    r"\b(I am|I'm|it is|it's|my name is|this is|call me)\s+"
    r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
    caseSensitive: false,
  );

  static final _bareIsName = RegExp(
    r'\b(is|was)\s+([A-Z][a-z]+)\b',
    caseSensitive: false,
  );

  /// Model typo: "Shakhzod l" after partial redaction.
  static final _nameTypoFragment = RegExp(r'\b[A-Z][a-z]+\s+[a-z]{1,2}\b');

  static final _titleName = RegExp(
    r'\b(Mr|Mrs|Ms|Miss|Dr)\.?\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
    caseSensitive: false,
  );

  static final _roleName = RegExp(
    r'\b((?:contact|call|reach|ask for)\s+)?'
    r'(agent|officer|representative|inspector)\s+'
    r'([A-Z][a-z]+)\b',
    caseSensitive: false,
  );

  static final _labeledSecret = RegExp(
    r'\b((?:your\s+)?(?:api[_\s-]?key|secret(?:[_\s-]?key)?|'
    r'access[_\s-]?token|auth[_\s-]?token|password|pin|otp|'
    r'bearer(?:\s+token)?)(?:\s+is|:|=))\s+'
    r'([A-Za-z0-9._\-+/=]{8,})\b',
    caseSensitive: false,
  );

  static final _unlabeledApiKey = RegExp(
    r'\b((?:there\s+is\s+)?(?:an?\s+)?api\s+key\s+)'
    r'([A-Za-z0-9._\-+/=]{8,})\b',
    caseSensitive: false,
  );

  static final _skPrefix = RegExp(r'\bsk-[A-Za-z0-9]{16,}\b');

  static final _highEntropyToken = RegExp(
    r'\b(?=[A-Za-z0-9]{16,}\b)(?=[A-Za-z]*[0-9])(?=[0-9]*[A-Za-z])[A-Za-z0-9]+\b',
  );

  static final _capitalizedToken = RegExp(r'\b[A-Z][a-z]{2,}\b');

  static const _typoSecondWordStop = {
    'is',
    'to',
    'at',
    'of',
    'in',
    'on',
    'or',
    'an',
    'as',
    'be',
    'we',
    'he',
    'if',
    'so',
    'up',
    'by',
    'my',
    'me',
    'go',
    'do',
    'no',
    'am',
    'it',
    'us',
    'the',
    'and',
    'for',
    'are',
    'was',
    'had',
    'has',
    'her',
    'his',
    'not',
  };

  static const _capitalizedAllowlist = {
    'microsoft',
    'amazon',
    'google',
    'apple',
    'meta',
    'netflix',
    'paypal',
    'visa',
    'mastercard',
    'wells',
    'fargo',
    'chase',
    'citibank',
    'bank',
    'irs',
    'fbi',
    'cia',
    'ssa',
    'dmv',
    'fedex',
    'ups',
    'usps',
    'dhl',
    'hello',
    'dear',
    'hi',
    'hey',
    'greetings',
    'thanks',
    'thank',
    'final',
    'notice',
    'urgent',
    'important',
    'attention',
    'warning',
    'contact',
    'call',
    'reach',
    'agent',
    'officer',
    'representative',
    'inspector',
    'support',
    'team',
    'service',
    'customer',
    'security',
    'account',
    'pay',
    'gift',
    'cards',
    'card',
    'legal',
    'action',
    'warrant',
    'arrest',
    'taxes',
    'today',
    'tomorrow',
    'immediately',
    'there',
    'your',
    'our',
    'they',
    'this',
    'that',
    'from',
    'with',
    'have',
    'been',
    'will',
    'must',
    'please',
    'company',
    'inc',
    'llc',
    'corp',
    'ltd',
    'api',
    'key',
    'secret',
    'token',
    'password',
    'pin',
    'otp',
    'bearer',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
    'american',
    'express',
    'western',
    'union',
    'bitcoin',
    'crypto',
    'transfer',
    'payment',
    'invoice',
    'order',
    'delivery',
    'package',
    'parcel',
    'refund',
    'prize',
    'winner',
    'lottery',
    'fed',
    'treasury',
    'department',
    'administration',
    'reply',
    'before',
    'noon',
    'internationalization',
    'difficult',
    'calling',
    'safe',
    'suspicious',
    'dangerous',
  };
}
