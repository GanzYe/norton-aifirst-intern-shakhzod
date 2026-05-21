/// Validation error for empty or too-short user input.
class AnalyzeMessageException implements Exception {
  const AnalyzeMessageException(this.message);

  final String message;

  @override
  String toString() => message;
}
