/// Deterministic PII masking — structured patterns only (no broad sweeps).
///
/// Only redacts high-confidence PII: emails, phones, financial IDs, secrets,
/// and names tied to explicit linguistic cues (greetings, roles, titles).
/// Scam narrative words (Congratulations, Norton, Claim, etc.) are preserved.
abstract final class PiiRegexScrubber {
  static String scrub(String input) {
    var text = input;
    for (var pass = 0; pass < 3; pass++) {
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
    for (final m in _greetingName.allMatches(text)) {
      final name = m.group(2)!;
      if (_looksLikePersonName(name) && !_isAllowlistedNamePhrase(name)) {
        return true;
      }
    }
    for (final m in _selfIdentityName.allMatches(text)) {
      final name = m.group(2)!;
      if (_looksLikePersonName(name) && !_isAllowlistedNamePhrase(name)) {
        return true;
      }
    }
    for (final m in _bareIsName.allMatches(text)) {
      final name = m.group(2)!;
      if (_looksLikePersonName(name) && !_isAllowlistedNamePhrase(name)) {
        return true;
      }
    }
    for (final m in _titleName.allMatches(text)) {
      if (_looksLikePersonName(m.group(2)!)) return true;
    }
    for (final m in _roleName.allMatches(text)) {
      if (_looksLikePersonName(m.group(3)!)) return true;
    }
    if (_hasUnredactedSecretMatch(text)) return true;
    if (_hasRepeatedPersonalName(text)) return true;
    return false;
  }

  static String _scrubPass(String input) {
    var text = input;

    text = _replaceAllMapped(text, _email, (_) => '[REDACTED_EMAIL]');
    text = _replaceAllMapped(text, _phone, (_) => '[REDACTED_PHONE]');
    text = _replaceAllMapped(text, _ssn, (_) => '[REDACTED_SSN]');
    text = _replaceAllMapped(text, _card, (_) => '[REDACTED_CARD]');

    text = _replaceAllMapped(text, _greetingName, (m) {
      final name = m.group(2)!;
      if (!_looksLikePersonName(name) || _isAllowlistedNamePhrase(name)) {
        return m.group(0)!;
      }
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _selfIdentityName, (m) {
      final name = m.group(2)!;
      if (!_looksLikePersonName(name) || _isAllowlistedNamePhrase(name)) {
        return m.group(0)!;
      }
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _bareIsName, (m) {
      final name = m.group(2)!;
      if (!_looksLikePersonName(name) || _isAllowlistedNamePhrase(name)) {
        return m.group(0)!;
      }
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _titleName, (m) {
      final name = m.group(2)!;
      if (!_looksLikePersonName(name)) return m.group(0)!;
      return '${m.group(1)} [REDACTED_NAME]';
    });

    text = _replaceAllMapped(text, _roleName, (m) {
      final prefix = m.group(1) ?? '';
      final role = m.group(2)!;
      final name = m.group(3)!;
      if (!_looksLikePersonName(name)) return m.group(0)!;
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

    return _redactRepeatedPersonalNames(text);
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

  /// Redacts a proper name only when it appears 2+ times (likely a person).
  static String _redactRepeatedPersonalNames(String text) {
    final counts = <String, int>{};
    for (final m in _properNameToken.allMatches(text)) {
      final word = m.group(0)!;
      if (!_isLikelyPersonalNameToken(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }

    var out = text;
    for (final entry in counts.entries) {
      if (entry.value < 2) continue;
      out = out.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b'),
        '[REDACTED_NAME]',
      );
    }
    return out;
  }

  static bool _hasRepeatedPersonalName(String text) {
    final counts = <String, int>{};
    for (final m in _properNameToken.allMatches(text)) {
      final word = m.group(0)!;
      if (!_isLikelyPersonalNameToken(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
      if (counts[word]! >= 2) return true;
    }
    return false;
  }

  static bool _isLikelyPersonalNameToken(String word) {
    if (_isAlreadyRedacted(word)) return false;
    if (word.length < 3 || word.length > 24) return false;
    if (_commonWordAllowlist.contains(word.toLowerCase())) return false;
    return true;
  }

  static bool _isAllowlistedNamePhrase(String phrase) {
    return phrase
        .split(RegExp(r'\s+'))
        .every((w) => _commonWordAllowlist.contains(w.toLowerCase()));
  }

  /// Title Case token(s) only — avoids matching "was delivered", "is resolved".
  static bool _looksLikePersonName(String phrase) {
    final parts = phrase.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return false;
    for (final part in parts) {
      if (part.length < 2) return false;
      final first = part[0];
      if (first != first.toUpperCase() || first == first.toLowerCase()) {
        return false;
      }
      if (part.length > 1) {
        final rest = part.substring(1);
        if (rest != rest.toLowerCase()) return false;
      }
    }
    return true;
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

  /// Requires a phone-like shape; avoids matching bare dollar amounts.
  static final _phone = RegExp(
    r'\b(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)\d{3}[-.\s]?\d{4}\b|'
    r'\b\+?\d{10,14}\b',
  );

  static final _ssn = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');

  static final _card = RegExp(r'\b(?:\d{4}[-\s]?){3}\d{4}\b');

  static final _greetingName = RegExp(
    r'\b(Hello|hello|Hi|hi|Hey|hey|Dear|dear|Greetings|greetings)\s+'
    r'([A-Z][a-z]+)\b',
  );

  static final _selfIdentityName = RegExp(
    r"\b(I am|i am|I'm|i'm|it is|it's|It is|my name is|this is|call me)\s+"
    r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
  );

  /// "is Shakhzod" / "was John" — not "is Microsoft" (allowlisted).
  static final _bareIsName = RegExp(
    r'\b(is|was)\s+([A-Z][a-z]+)\b',
  );

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

  static final _properNameToken = RegExp(r'\b[A-Z][a-z]+\b');

  static const _commonWordAllowlist = {
    'microsoft',
    'amazon',
    'google',
    'apple',
    'meta',
    'netflix',
    'paypal',
    'visa',
    'mastercard',
    'norton',
    'irs',
    'fbi',
    'dhl',
    'fedex',
    'ups',
    'usps',
    'hello',
    'dear',
    'hi',
    'hey',
    'thanks',
    'thank',
    'congratulations',
    'final',
    'notice',
    'urgent',
    'important',
    'attention',
    'warning',
    'contact',
    'call',
    'agent',
    'officer',
    'support',
    'team',
    'service',
    'customer',
    'security',
    'account',
    'pay',
    'gift',
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
    'api',
    'key',
    'secret',
    'token',
    'password',
    'prize',
    'winner',
    'lottery',
    'loyalty',
    'draw',
    'claim',
    'reply',
    'stop',
    'opt',
    'out',
    'won',
    'you',
    'the',
    'and',
    'for',
    'are',
    'was',
    'not',
    'internationalization',
    'difficult',
    'calling',
    'delivery',
    'parcel',
    'package',
    'scheduled',
    'appointment',
    'reminder',
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
  };
}
