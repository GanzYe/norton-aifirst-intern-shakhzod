import 'package:flutter_test/flutter_test.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/pii_regex_scrubber.dart';

void main() {
  group('PiiRegexScrubber', () {
    test('masks email and keeps surrounding text', () {
      const input = 'Reply to john.doe@example.com before noon.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, 'Reply to [REDACTED_EMAIL] before noon.');
      expect(PiiRegexScrubber.containsDetectablePii(out), isFalse);
    });

    test('masks all name occurrences including bare "is Name"', () {
      const input =
          'Hello Shakhzod is Shakhzod. It is Shakhzod. '
          'i am Shakhzod from company Microsoft.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, isNot(contains('Shakhzod')));
      expect(out, contains('Microsoft'));
      expect(out, contains('Hello [REDACTED_NAME]'));
      expect(PiiRegexScrubber.containsDetectablePii(out), isFalse);
    });

    test('fixes model leak pattern from production logs', () {
      const input =
          'Hello [REDACTED_NAME] is Shakhzod l. It is [REDACTED_NAME]. '
          'There is api key [REDACTED_SECRET]. '
          'i am [REDACTED_NAME] company Microsoft';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, isNot(contains('Shakhzod')));
      expect(out, contains('Microsoft'));
      expect(PiiRegexScrubber.containsDetectablePii(out), isFalse);
    });

    test('masks API key label but keeps narrative', () {
      const input =
          "Hello Shakhzod. Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.";
      final out = PiiRegexScrubber.scrub(input);
      expect(out, contains('Hello [REDACTED_NAME]'));
      expect(out, contains('Your API key is [REDACTED_SECRET]'));
      expect(out, isNot(contains('AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM')));
    });

    test('keeps Contact agent phrase structure', () {
      const input = 'Contact agent Smith immediately.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, 'Contact agent [REDACTED_NAME] immediately.');
    });

    test('preserves IRS scam body', () {
      const input =
          'Final Notice from IRS: Pay \$4,250 via gift cards. '
          'Contact agent Smith at john@scam.test.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, contains('Final Notice from IRS'));
      expect(out, contains('\$4,250'));
      expect(out, contains('Contact agent [REDACTED_NAME]'));
      expect(out, contains('[REDACTED_EMAIL]'));
    });

    test('does not mask long plain words without digits', () {
      const input = 'Internationalization is difficult.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, input);
    });

    test('does not mask "is Microsoft"', () {
      const input = 'This is Microsoft support calling.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, contains('Microsoft'));
      expect(out, isNot(contains('[REDACTED_NAME]')));
    });

    test('detects leftover secrets after scrub', () {
      expect(
        PiiRegexScrubber.containsDetectablePii(
          'Hello [REDACTED_NAME]. Your API key is [REDACTED_SECRET].',
        ),
        isFalse,
      );
      expect(
        PiiRegexScrubber.containsDetectablePii(
          'Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM',
        ),
        isTrue,
      );
    });
  });
}
