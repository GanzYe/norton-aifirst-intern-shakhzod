/// Domain-level failure reasons for the analysis pipeline.
sealed class AnalysisFailure {
  const AnalysisFailure();

  String get message;
}

/// Cloud providers (Groq → Gemini) exhausted or unavailable.
final class CloudAnalysisFailure extends AnalysisFailure {
  const CloudAnalysisFailure([this.message = 'Cloud analysis is unavailable.']);

  @override
  final String message;
}

/// On-device model could not produce a verdict.
final class LocalAnalysisFailure extends AnalysisFailure {
  const LocalAnalysisFailure([
    this.message = "Couldn't complete on-device analysis.",
  ]);

  @override
  final String message;
}

/// Device connectivity could not be determined or is unavailable.
final class ConnectivityFailure extends AnalysisFailure {
  const ConnectivityFailure([
    this.message = 'Could not verify network connectivity.',
  ]);

  @override
  final String message;
}

/// PII scrubbing failed while Incognito mode requires redaction before cloud.
final class PiiScrubFailure extends AnalysisFailure {
  const PiiScrubFailure([
    this.message =
        'On-device privacy scrubbing failed. Analysis was stopped to protect '
        'your data.',
  ]);

  @override
  final String message;
}
