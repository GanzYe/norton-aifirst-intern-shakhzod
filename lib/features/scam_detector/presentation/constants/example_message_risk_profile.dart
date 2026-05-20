import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';

/// Heuristic tiering aligned with the Groq/Gemini rubric in cloud prompts.
abstract final class ExampleMessageRiskProfile {
  static RiskLevel classify(String body) {
    if (_dangerousScore(body) >= 3) return RiskLevel.dangerous;
    if (_suspiciousScore(body) >= 2) return RiskLevel.suspicious;
    return RiskLevel.safe;
  }

  static bool matchesExpected(ExampleMessage sample) =>
      classify(sample.body) == sample.expectedRisk;

  static int _dangerousScore(String body) {
    final lower = body.toLowerCase();
    var score = 0;
    if (RegExp(r'bit\.ly/|\.xyz/|\.tk/|\.top/').hasMatch(lower)) score += 3;
    if (lower.contains('verify immediately at http')) score += 3;
    if (lower.contains('account will be suspended')) score += 2;
    if (RegExp(r'won \$|1,000,000').hasMatch(body)) score += 3;
    if (lower.contains('claim your prize now')) score += 2;
    if (lower.contains('reply claim')) score += 2;
    if (RegExp(r'call 1-\d{3}-\d{3}-\d{4}').hasMatch(body) &&
        lower.contains('minutes')) {
      score += 2;
    }
    return score;
  }

  static int _suspiciousScore(String body) {
    final lower = body.toLowerCase();
    var score = 0;
    if (lower.contains('sign-in from a new app') ||
        lower.contains('if this was not you')) {
      score += 3;
    }
    if (lower.contains('past-due') ||
        lower.contains('lose service tonight')) {
      score += 2;
    }
    if (RegExp('microsoft|t-mobile|dhl|amazon', caseSensitive: false)
        .hasMatch(body)) {
      score += 1;
    }
    return score;
  }
}
