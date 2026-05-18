import 'dart:developer' as developer;

import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';

const _piiSystemPrompt =
    'Redact all PII from the following text, replacing it with [REDACTED]. '
    'Return only the scrubbed text without any additional commentary.';

/// On-device PII scrubbing via flutter_llama; regex fallback when model unavailable.
class LocalPiiRedactionService implements PiiRedactionRepository {
  LocalPiiRedactionService({
    required FlutterLlama llama,
    required String modelPath,
  })  : _llama = llama,
        _modelPath = modelPath;

  final FlutterLlama _llama;
  final String _modelPath;

  bool _modelLoaded = false;

  @override
  Future<String> scrubPii(String input) async {
    if (_modelPath.isEmpty) {
      developer.log(
        'LLAMA_MODEL_PATH unset; using regex PII fallback.',
        name: 'LocalPiiRedactionService',
      );
      return _regexFallback(input);
    }

    try {
      await _ensureModelLoaded();
      final params = GenerationParams(
        prompt: '$_piiSystemPrompt\n\n$input',
        temperature: 0.1,
        topP: 0.9,
        topK: 40,
        maxTokens: 1024,
        repeatPenalty: 1.1,
      );

      final buffer = StringBuffer();
      await for (final token in _llama.generateStream(params)) {
        buffer.write(token);
      }

      final scrubbed = buffer.toString().trim();
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
      return _regexFallback(input);
    }
  }

  Future<void> _ensureModelLoaded() async {
    if (_modelLoaded) {
      return;
    }

    final config = LlamaConfig(
      modelPath: _modelPath,
      nThreads: 4,
      nGpuLayers: -1,
      contextSize: 2048,
      batchSize: 512,
      useGpu: true,
      verbose: false,
    );

    final loaded = await _llama.loadModel(config);
    if (!loaded) {
      throw const PiiRedactionException('Failed to load local Llama model.');
    }
    _modelLoaded = true;
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
