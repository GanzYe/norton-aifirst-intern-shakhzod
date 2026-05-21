/// Thrown when the cloud cascade (Groq → Gemini) cannot return a verdict.
class CloudAnalysisExhaustedException implements Exception {
  const CloudAnalysisExhaustedException([
    this.message =
        'Analysis is currently unavailable. Please try again in a moment.',
  ]);

  final String message;

  @override
  String toString() => message;
}
