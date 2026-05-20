import 'package:flutter_test/flutter_test.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/pii_regex_scrubber.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';

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
          'Hello Shakhzod. Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.';
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

    test('preserves prize scam narrative words', () {
      const input =
          r'Congratulations! You won $1,000,000 in the Norton Loyalty Draw. '
          'Claim your prize now: bit.ly/prize-winner-claim. Reply STOP to opt out.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, input);
      expect(out, isNot(contains('[REDACTED_NAME]')));
    });

    test('preserves IRS scam body', () {
      const input =
          r'Final Notice from IRS: Pay $4,250 via gift cards. '
          'Contact agent Smith at john@scam.test.';
      final out = PiiRegexScrubber.scrub(input);
      expect(out, contains('Final Notice from IRS'));
      expect(out, contains(r'$4,250'));
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

    test('does not treat "was delivered" or "is Monday" as names', () {
      const fedEx =
          'Your FedEx parcel #4829103 was delivered to your front door at '
          '2:15 PM. Track at fedex.com or reply HELP for support.';
      expect(PiiRegexScrubber.scrub(fedEx), fedEx);

      const dentist =
          'Reminder: Your dentist appointment is Monday at 10:30 AM. '
          'Reply YES to confirm or call the office to reschedule.';
      expect(PiiRegexScrubber.scrub(dentist), dentist);
    });

    test('home screen safe examples stay unchanged', () {
      for (final sample in ExampleMessages.withRisk(RiskLevel.safe)) {
        expect(PiiRegexScrubber.scrub(sample.body), sample.body);
      }
    });

    test('dangerous bank example redacts phone only', () {
      const body =
          'URGENT: Your bank account will be suspended within 24 hours. '
          'Verify immediately at http://secure-bank-verify.xyz/login '
          'or call 1-800-555-0199.';
      final out = PiiRegexScrubber.scrub(body);
      expect(out, contains('[REDACTED_PHONE]'));
      expect(out, isNot(contains('1-800-555-0199')));
      expect(out, contains('secure-bank-verify.xyz'));
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
