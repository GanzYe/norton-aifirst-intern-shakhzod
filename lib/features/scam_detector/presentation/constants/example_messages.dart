import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';

/// Tap-to-fill demo messages with an expected classifier verdict.
class ExampleMessage {
  const ExampleMessage({
    required this.title,
    required this.body,
    required this.expectedRisk,
  });

  final String title;
  final String body;
  final RiskLevel expectedRisk;
}

/// Tap-to-fill examples for the home screen (2 per risk tier).
abstract final class ExampleMessages {
  static const _buildPrompt = BuildAugmentedPromptUseCase();

  static const List<ExampleMessage> samples = [
    ExampleMessage(
      title: 'Safe · Delivery update',
      body:
          'Your FedEx parcel #4829103 was delivered to your front door at '
          '2:15 PM. Track at fedex.com or reply HELP for support.',
      expectedRisk: RiskLevel.safe,
    ),
    ExampleMessage(
      title: 'Safe · Appointment reminder',
      body:
          'Reminder: Your dentist appointment is Monday at 10:30 AM. '
          'Reply YES to confirm or call the office to reschedule.',
      expectedRisk: RiskLevel.safe,
    ),
    ExampleMessage(
      title: 'Suspicious · Unusual sign-in',
      body:
          'Microsoft account: Sign-in from a new app on Android in Mexico City. '
          'If this was not you, reset your password the next time you sign in.',
      expectedRisk: RiskLevel.suspicious,
    ),
    ExampleMessage(
      title: 'Suspicious · Billing past due',
      body:
          'T-Mobile: Line ending 0142 may lose service tonight unless a past-due '
          'balance of \$38.15 is resolved. Pay only through the My T-Mobile app '
          'you already installed — not through links in texts.',
      expectedRisk: RiskLevel.suspicious,
    ),
    ExampleMessage(
      title: 'Dangerous · Fake bank alert',
      body:
          'URGENT: Your bank account will be suspended within 24 hours. '
          'Verify immediately at http://secure-bank-verify.xyz/login '
          'or call 1-800-555-0199.',
      expectedRisk: RiskLevel.dangerous,
    ),
    ExampleMessage(
      title: 'Dangerous · Prize scam SMS',
      body:
          r'Congratulations! You won $1,000,000 in the Norton Loyalty Draw. '
          'Claim your prize now: bit.ly/prize-winner-claim. '
          'Reply STOP to opt out.',
      expectedRisk: RiskLevel.dangerous,
    ),
  ];

  static List<ExampleMessage> withRisk(RiskLevel risk) =>
      samples.where((s) => s.expectedRisk == risk).toList(growable: false);

  /// Same master prompt shape the online orchestrator sends to Groq/Gemini.
  static String masterPromptFor(
    ExampleMessage sample, {
    bool incognitoPlainText = true,
  }) {
    return _buildPrompt(
      scrubbedInput: sample.body,
      intel: ThreatIntelSnapshot(
        osintSkippedDueToIncognito: incognitoPlainText,
      ),
    );
  }
}
