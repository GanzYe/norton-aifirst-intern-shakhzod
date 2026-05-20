import 'dart:async';

import 'package:flutter_llama/flutter_llama.dart';

/// Qwen2.5-Instruct ChatML delimiters (must match the model tokenizer).
const kChatMlImStart = '<|im_start|>';

/// Built from code units so tooling cannot corrupt the special token string.
final kChatMlImEnd = String.fromCharCodes(<int>[
  60,
  124,
  105,
  109,
  95,
  101,
  110,
  100,
  124,
  62,
]);

/// Serializes [FlutterLlama] access and coordinates native cancel/unload.
///
/// flutter_llama 1.1.2 holds a process-wide mutex during `generate()`.
/// Calling `unloadModel()` while generation is still running blocks the Android
/// main thread (MIUI APP_SCOUT_HANG). Always `stopGeneration()` and wait for
/// the in-flight `generate()` future to settle before unloading.
class LocalLlamaInference {
  LocalLlamaInference(this._llama);

  final FlutterLlama _llama;

  static Future<void> _chain = Future<void>.value();

  /// Runs [operation] after any prior Llama work on this isolate finishes.
  static Future<T> runExclusive<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        if (!completer.isCompleted) {
          completer.complete(await operation());
        }
      } on Object catch (e, stack) {
        if (!completer.isCompleted) {
          completer.completeError(e, stack);
        }
      }
    });
    return completer.future;
  }

  Future<bool> loadModel(
    LlamaConfig config, {
    Duration timeout = const Duration(seconds: 45),
  }) {
    return _llama.loadModel(config).timeout(timeout);
  }

  Future<LlamaResponse> generate(
    GenerationParams params, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final Future<LlamaResponse> generation;
    try {
      generation = _llama.generate(params);
    } on Object catch (e, stack) {
      await _requestNativeStop();
      Error.throwWithStackTrace(e, stack);
    }

    try {
      return await generation.timeout(timeout);
    } on Object {
      await _settleInFlightGeneration(generation);
      rethrow;
    }
  }

  Future<void> _requestNativeStop() async {
    try {
      await _llama
          .stopGeneration()
          .timeout(const Duration(seconds: 4));
    } on Object {
      // Best-effort.
    }
  }

  Future<void> unloadModel() async {
    try {
      await _llama.unloadModel().timeout(const Duration(seconds: 15));
    } on Object {
      // Best-effort teardown; a stuck native free must not crash the app.
    }
  }

  Future<void> _settleInFlightGeneration(
    Future<LlamaResponse> generation,
  ) async {
    // stopGeneration is a blocking JNI call on the Android platform thread.
    // Cap it so a stuck native mutex cannot hang the UI past this budget.
    await _requestNativeStop();
    try {
      await generation.timeout(const Duration(seconds: 12));
    } on Object {
      // Timed-out or failed generation — mutex should be released now.
    }
  }

  /// Token budget for short structured outputs (PII rewrite, JSON verdict).
  static int outputTokenBudget({
    required int inputChars,
    int minTokens = 64,
    int maxTokens = 320,
  }) {
    final estimate = (inputChars * 1.35).round() + 48;
    return estimate.clamp(minTokens, maxTokens);
  }
}
