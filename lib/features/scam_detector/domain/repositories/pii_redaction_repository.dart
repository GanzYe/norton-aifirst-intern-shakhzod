abstract interface class PiiRedactionRepository {
  Future<String> scrubPii(String input);
}

class PiiRedactionException implements Exception {
  const PiiRedactionException(this.message);

  final String message;

  @override
  String toString() => message;
}
