import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/analysis_outcome.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/analysis_failure.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/analyze_message_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/cloud_analysis_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/local_analysis_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/pii_scrub_failure_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_analysis_controller.dart';

/// Maps any thrown analysis error to user-friendly copy.
String friendlyAnalysisError(Object? error) {
  if (error == null) {
    return 'Analysis failed. Please try again.';
  }

  if (error is AnalyzeMessageException) {
    return error.message;
  }

  if (error is ModelDownloadException) {
    return error.message;
  }

  if (error is AnalysisFailedException) {
    final inner = error.message;
    return _looksLikeUserMessage(inner)
        ? inner
        : 'Analysis is unavailable right now. Please try again in a moment.';
  }

  if (error is PiiScrubFailureException) {
    return error.message;
  }

  if (error is CloudAnalysisExhaustedException) {
    return 'Analysis is currently unavailable. Please try again in a moment.';
  }

  if (error is LocalAnalysisException) {
    return "Couldn't run on-device analysis. Please try again, or connect "
        'to the internet for full analysis.';
  }

  if (error is PiiRedactionException) {
    return 'On-device privacy scrubbing failed. Please try again.';
  }

  return 'Analysis failed. Please try again.';
}

/// User-facing copy for non-throwing [AnalysisOutcome] error states.
String friendlyOutcomeMessage(AnalysisOutcome outcome) {
  return switch (outcome) {
    LocalModelUnavailable() =>
      "No internet connection and the local model hasn't been downloaded yet. "
      'Please connect to the internet to analyze this message, or enable '
      'Incognito mode to download the on-device model.',
    AnalysisError(:final failure) => switch (failure) {
      PiiScrubFailure() => failure.message,
      LocalAnalysisFailure() =>
        "We couldn't complete on-device analysis for this message. "
            'Please connect to the internet for full analysis, or try '
            'again in a moment.',
      CloudAnalysisFailure() =>
        'Cloud analysis is currently unavailable. '
            'Please try again in a moment.',
      ConnectivityFailure() => failure.message,
    },
    AnalysisSuccess() => '',
  };
}

bool _looksLikeUserMessage(String message) {
  if (message.isEmpty) return false;
  final lower = message.toLowerCase();
  const noise = [
    'exception',
    'stacktrace',
    'stack trace',
    'platformexception',
    'http',
    'status',
    'null check',
    "type '",
    'package:',
  ];
  return noise.every((token) => !lower.contains(token));
}
