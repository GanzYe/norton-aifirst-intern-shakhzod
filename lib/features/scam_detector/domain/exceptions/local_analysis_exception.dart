/// Thrown when on-device scam analysis fails.
class LocalAnalysisException implements Exception {
  const LocalAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
