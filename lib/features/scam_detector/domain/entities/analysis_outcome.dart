import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/analysis_failure.dart';

/// Result of a full SOAR analysis run (replaces sentinel [ScamAnalysis] flags).
sealed class AnalysisOutcome {
  const AnalysisOutcome();
}

/// Successful verdict with optional pipeline trace on [result].
final class AnalysisSuccess extends AnalysisOutcome {
  const AnalysisSuccess(this.result);

  final ScamAnalysis result;
}

/// Offline path: no network and on-device model not downloaded.
final class LocalModelUnavailable extends AnalysisOutcome {
  const LocalModelUnavailable();
}

/// Recoverable or terminal failure surfaced to the UI without a verdict card.
final class AnalysisError extends AnalysisOutcome {
  const AnalysisError(this.failure);

  final AnalysisFailure failure;
}
