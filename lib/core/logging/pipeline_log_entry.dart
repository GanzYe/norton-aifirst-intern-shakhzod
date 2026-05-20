/// One line (or multi-line detail) from the SOAR analysis pipeline trace.
class PipelineLogEntry {
  PipelineLogEntry({
    required this.tag,
    required this.stage,
    this.message,
    this.context,
    this.detail,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String tag;
  final String stage;
  final String? message;
  final Map<String, String>? context;
  final String? detail;
  final String? error;
  final DateTime timestamp;

  /// Single-line summary matching [PipelineLog] console format.
  String get summaryLine {
    final buf = StringBuffer()
      ..write('[')
      ..write(tag)
      ..write('] ')
      ..write(stage);
    if (message != null && message!.isNotEmpty) {
      buf
        ..write(' • ')
        ..write(message);
    }
    if (context != null && context!.isNotEmpty) {
      buf
        ..write(' | ')
        ..write(context!.entries.map((e) => '${e.key}=${e.value}').join(', '));
    }
    if (error != null && error!.isNotEmpty) {
      buf
        ..write(' | error=')
        ..write(error);
    }
    return buf.toString();
  }

  bool get hasDetail => detail != null && detail!.isNotEmpty;
}
