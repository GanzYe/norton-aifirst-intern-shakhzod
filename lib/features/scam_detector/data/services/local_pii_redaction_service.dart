import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/llama_native_probe.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';

const _piiSystemPrompt =
    'Redact all PII from the following text, replacing it with [REDACTED]. '
    'Return only the scrubbed text without any additional commentary.';

/// On-device PII scrubbing via flutter_llama with a regex fallback. The
/// regex path is always used when the native engine isn't loadable or the
/// model isn't on disk, so this method never bubbles a failure upward.
class LocalPiiRedactionService implements PiiRedactionRepository {
  LocalPiiRedactionService({
    required FlutterLlama llama,
    required ModelDownloadService modelDownloadService,
    required LlamaNativeProbe nativeProbe,
  })  : _llama = llama,
        _modelDownload = modelDownloadService,
        _nativeProbe = nativeProbe;

  static const _loadTimeout = Duration(seconds: 45);
  static const _generateTimeout = Duration(minutes: 1);

  final FlutterLlama _llama;
  final ModelDownloadService _modelDownload;
  final LlamaNativeProbe _nativeProbe;

  bool _modelLoaded = false;
  String? _loadedFromPath;

  @override
  Future<String> scrubPii(String input) async {
    if (!await _modelDownload.isModelDownloaded()) {
      developer.log(
        'Local model not downloaded; using regex PII fallback.',
        name: 'LocalPiiRedactionService',
      );
      return _regexFallback(input);
    }
    if (!await _nativeProbe.isAvailable()) {
      developer.log(
        'Llama native libraries unavailable; using regex PII fallback.',
        name: 'LocalPiiRedactionService',
      );
      return _regexFallback(input);
    }

    try {
      final modelPath = await _modelDownload.getModelPath();
      await _ensureModelLoaded(modelPath);

      final params = GenerationParams(
        prompt: '$_piiSystemPrompt\n\n$input',
        temperature: 0.1,
        topP: 0.9,
        topK: 40,
        maxTokens: 1024,
        repeatPenalty: 1.1,
      );

      // Non-streaming generate() avoids the flutter_llama 1.1.2 EventChannel
      // race condition (NO_EVENT_SINK).
      final response = await _llama.generate(params).timeout(_generateTimeout);
      final scrubbed = response.text.trim();
      if (scrubbed.isEmpty) {
        return _regexFallback(input);
      }
      return scrubbed;
    } on Object catch (e, stack) {
      developer.log(
        'Local LLM redaction failed; using regex fallback.',
        name: 'LocalPiiRedactionService',
        error: e,
        stackTrace: stack,
      );
      _modelLoaded = false;
      _loadedFromPath = null;
      return _regexFallback(input);
    }
  }

  Future<void> _ensureModelLoaded(String modelPath) async {
    if (_modelLoaded && _loadedFromPath == modelPath) {
      return;
    }

    final config = LlamaConfig(
      modelPath: modelPath,
      nThreads: 4,
      nGpuLayers: 0,
      contextSize: 2048,
      batchSize: 256,
      useGpu: false,
      verbose: false,
    );

    final loaded = await _llama.loadModel(config).timeout(_loadTimeout);
    if (!loaded) {
      throw const PiiRedactionException('Failed to load local Llama model.');
    }
    _modelLoaded = true;
    _loadedFromPath = modelPath;
  }

  String _regexFallback(String input) {
    var result = input;
    result = result.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[REDACTED_EMAIL]',
    );
    result = result.replaceAll(
      RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
      '[REDACTED_PHONE]',
    );
    result = result.replaceAll(
      RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
      '[REDACTED_SSN]',
    );
    result = result.replaceAll(
      RegExp(
        r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
      ),
      '[REDACTED_CARD]',
    );
    return result;
  }
}
