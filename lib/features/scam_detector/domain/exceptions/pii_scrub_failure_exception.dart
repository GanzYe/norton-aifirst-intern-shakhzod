import 'package:scam_message_detector/features/scam_detector/domain/exceptions/analysis_failure.dart';

/// Thrown when Incognito mode is on and PII scrubbing cannot complete.
/// Analysis must not proceed to cloud with unscrubbed content.
class PiiScrubFailureException implements Exception {
  const PiiScrubFailureException([
    this.message =
        'On-device privacy scrubbing failed. Analysis was stopped to protect '
        'your data.',
  ]);

  final String message;

  PiiScrubFailure get failure => PiiScrubFailure(message);

  @override
  String toString() => message;
}
