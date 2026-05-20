import 'dart:developer' as developer;

import 'package:scam_message_detector/core/logging/pipeline_log_entry.dart';

/// Centralized, stage-aware logger for the SOAR scam-detection pipeline.
///
/// Every service in the analysis pipeline emits trace events through this
/// helper so a single `dart:developer` log scope (`PipelineLog`) lets you
/// follow a request end-to-end:
///
///   1. CONNECTIVITY        – online/offline routing decision
///   2. CLASSIFY            – input kind (text / url / ip / eml)
///   3. EML_PARSE           – MIME parse + Authentication-Results
///   4. PII                 – on-device LLM scrub (or regex fallback)
///   5. OSINT.VT            – VirusTotal URL reputation
///   6. OSINT.AbuseIPDB     – IP reputation
///   7. OSINT.URLScan       – urlscan.io submission
///   8. PROMPT              – augmented master-prompt assembly
///   9. GROQ                – primary cloud LLM (llama-3.3-70b-versatile)
///  10. GEMINI              – fallback cloud LLM (gemini-2.5-flash-lite)
///  11. LLAMA_LOCAL         – on-device Qwen2.5-1.5B fallback
///  12. ORCHESTRATOR        – top-level pipeline events
///  13. MODEL_ROUTE         – payload routed to regional (cloud) vs local model
///
/// Each entry is rendered as:
///   `[TAG] STAGE • message | k1=v1, k2=v2`
///
/// where TAG is one of START / DONE / INFO / WARN / FAIL.
abstract final class PipelineLog {
  static const _name = 'PipelineLog';

  static List<PipelineLogEntry>? _capture;

  /// Starts collecting log entries for the current analysis (shown in UI).
  static void beginCapture() {
    _capture = [];
  }

  /// Returns captured entries and stops collection.
  static List<PipelineLogEntry> takeCapture() {
    final entries = List<PipelineLogEntry>.unmodifiable(_capture ?? const []);
    _capture = null;
    return entries;
  }

  /// Clears an in-progress capture without returning entries (e.g. on error).
  static void discardCapture() {
    _capture = null;
  }

  /// Pipeline stage entered. Pair with [done] or [failure].
  static void start(String stage, {Map<String, Object?>? context}) {
    _emit('START', stage, context: context);
  }

  /// A status update inside a stage (e.g. "calling VirusTotal /urls").
  static void info(
    String stage,
    String message, {
    Map<String, Object?>? context,
  }) {
    _emit('INFO', stage, message: message, context: context);
  }

  /// Stage completed successfully.
  static void done(
    String stage, {
    String? message,
    Map<String, Object?>? context,
  }) {
    _emit('DONE', stage, message: message, context: context);
  }

  /// Logs which model receives the analysis payload (regional cloud vs local).
  ///
  /// Emits a summary line plus a second log entry with the full [payload]
  /// (not truncated).
  static void modelRoute({
    required String target,
    required String model,
    required String payload,
  }) {
    info(
      'MODEL_ROUTE',
      'payload sent to $target model',
      context: {'model': model, 'payloadChars': payload.length},
    );
    _logFullBody('MODEL_ROUTE', 'payload → $target ($model)', payload);
  }

  /// Logs the raw text returned by a model (cloud or on-device).
  ///
  /// Emits a summary line plus a second log entry with the full [response].
  static void modelResponse({
    required String source,
    required String response,
  }) {
    info(
      'MODEL_RESPONSE',
      'response from $source',
      context: {'responseChars': response.length},
    );
    _logFullBody('MODEL_RESPONSE', source, response);
  }

  /// Logs raw text entering PII scrub (Incognito path).
  static void piiInput(String input) {
    info('PII', 'scrub input', context: {'inputChars': input.length});
    _logFullBody('PII', 'input', input);
  }

  /// Logs the user message chunk sent into the on-device PII model.
  static void piiModelPrompt(String userMessage) {
    info(
      'PII',
      'LLM user message',
      context: {'userMessageChars': userMessage.length},
    );
    _logFullBody('PII', 'LLM user message', userMessage);
  }

  /// Logs redacted text leaving PII scrub ([via] is `regex`, `llm+regex`, …).
  static void piiOutput(String output, {required String via}) {
    info(
      'PII',
      'scrub output',
      context: {'outputChars': output.length, 'via': via},
    );
    _logFullBody('PII', 'output ($via)', output);
  }

  static void _logFullBody(String stage, String label, String body) {
    _record(
      PipelineLogEntry(
        tag: 'INFO',
        stage: stage,
        message: '$label (${body.length} chars)',
        detail: body,
      ),
    );
    developer.log(
      '[$stage] $label (${body.length} chars):\n$body',
      name: _name,
      level: 800,
    );
  }

  /// Non-fatal anomaly (e.g. cloud rate-limit triggering fallback).
  static void warn(
    String stage,
    String message, {
    Map<String, Object?>? context,
    Object? error,
  }) {
    _emit(
      'WARN',
      stage,
      message: message,
      context: context,
      error: error,
      level: 900,
    );
  }

  /// Stage failed. Caller decides whether to propagate or fall back.
  static void failure(
    String stage,
    Object error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, Object?>? context,
  }) {
    _emit(
      'FAIL',
      stage,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void _emit(
    String tag,
    String stage, {
    String? message,
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
    int level = 800,
  }) {
    final buf = StringBuffer()
      ..write('[')
      ..write(tag)
      ..write('] ')
      ..write(stage);
    if (message != null && message.isNotEmpty) {
      buf
        ..write(' • ')
        ..write(message);
    }
    if (context != null && context.isNotEmpty) {
      buf
        ..write(' | ')
        ..write(
          context.entries.map((e) => '${e.key}=${_fmt(e.value)}').join(', '),
        );
    }
    final line = buf.toString();
    _record(
      PipelineLogEntry(
        tag: tag,
        stage: stage,
        message: message,
        context: _stringifyContext(context),
        error: error?.toString(),
      ),
    );
    developer.log(
      line,
      name: _name,
      error: error,
      stackTrace: stackTrace,
      level: level,
    );
  }

  static void _record(PipelineLogEntry entry) {
    _capture?.add(entry);
  }

  static Map<String, String>? _stringifyContext(Map<String, Object?>? context) {
    if (context == null || context.isEmpty) return null;
    return {
      for (final e in context.entries) e.key: _fmt(e.value),
    };
  }

  static String _fmt(Object? value) {
    if (value == null) return 'null';
    final s = value.toString();
    if (s.length > 120) return '${s.substring(0, 117)}...';
    return s;
  }
}
