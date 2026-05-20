import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_analysis_controller.dart';

/// Maps any thrown analysis error to user-friendly copy. Developer details
/// (stack traces, URLs, HTTP status codes, internal exception names) never
/// reach the UI; everything ends up as one of a small set of curated lines.
String friendlyAnalysisError(Object? error) {
  if (error == null) {
    return 'Analysis failed. Please try again.';
  }

  // Validation errors thrown from the use case already use plain language.
  if (error is AnalyzeMessageException) {
    return error.message;
  }

  // ModelDownload copy is already user-facing.
  if (error is ModelDownloadException) {
    return error.message;
  }

  if (error is AnalysisFailedException) {
    final inner = error.message;
    return _looksLikeUserMessage(inner)
        ? inner
        : 'Analysis is unavailable right now. Please try again in a moment.';
  }

  if (error is GeminiDataSourceException || error is GroqDataSourceException) {
    final raw = error.toString();
    if (_looksRateLimited(raw)) {
      return 'Our analysis service is busy right now. Please try again in a '
          'minute.';
    }
    if (_looksLikeAuthError(raw)) {
      return 'Cloud analysis is unavailable on this build. The app will use '
          'the on-device model instead when possible.';
    }
    return 'Cloud analysis is currently unavailable. Please try again in a '
        'moment.';
  }

  if (error is LocalScamAnalysisException) {
    return "Couldn't run on-device analysis. Please try again, or connect "
        'to the internet for full analysis.';
  }

  if (error is PiiRedactionException) {
    return 'On-device privacy scrubbing failed. Please try again.';
  }

  return 'Analysis failed. Please try again.';
}

bool _looksLikeUserMessage(String message) {
  if (message.isEmpty) return false;
  // Reject obviously developer-y payloads.
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

bool _looksRateLimited(String message) {
  final lower = message.toLowerCase();
  return lower.contains('quota') ||
      lower.contains('rate') ||
      lower.contains('429') ||
      lower.contains('exceeded');
}

bool _looksLikeAuthError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('api key') ||
      lower.contains('apikey') ||
      lower.contains('unauthor') ||
      lower.contains('401') ||
      lower.contains('403');
}
