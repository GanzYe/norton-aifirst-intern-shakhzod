import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';

const _scamAnalysisSystemPrompt = '''
You are a cybersecurity expert analyzing messages for scam, phishing, and fraud risk.
Respond with ONLY a valid JSON object and no other text:
{"risk_level":"SAFE"|"SUSPICIOUS"|"DANGEROUS","confidence":0-100,"explanation":"two to three sentences"}
Rules:
- SAFE: legitimate or low-risk content
- SUSPICIOUS: urgency, impersonation, odd links, or prize/lottery patterns
- DANGEROUS: clear phishing, credential theft, malware links, or financial fraud
''';

class LocalScamAnalysisException implements Exception {
  const LocalScamAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// On-device scam verdict via flutter_llama (offline analysis path).
///
/// The model path is resolved lazily from [ModelDownloadService] at each
/// [analyze] call so newly downloaded models become usable without a
/// provider rebuild race.
class LocalScamAnalysisService {
  LocalScamAnalysisService({
    required FlutterLlama llama,
    required ModelDownloadService modelDownloadService,
  })  : _llama = llama,
        _modelDownload = modelDownloadService;

  final FlutterLlama _llama;
  final ModelDownloadService _modelDownload;

  bool _modelLoaded = false;
  String? _loadedFromPath;

  /// True when a .gguf model file exists on device.
  Future<bool> isModelAvailable() => _modelDownload.isModelDownloaded();

  Future<ScamAnalysis> analyze(String message) async {
    if (!await _modelDownload.isModelDownloaded()) {
      throw const LocalScamAnalysisException(
        'Local model is not downloaded.',
      );
    }

    try {
      final modelPath = await _modelDownload.getModelPath();
      await _ensureModelLoaded(modelPath);

      final params = GenerationParams(
        prompt: '$_scamAnalysisSystemPrompt\n\nAnalyze this message:\n\n'
            '$message',
        temperature: 0.2,
        topP: 0.9,
        topK: 40,
        maxTokens: 512,
        repeatPenalty: 1.1,
      );

      // Non-streaming generate() avoids the EventChannel race condition in
      // flutter_llama 1.1.2 (NO_EVENT_SINK).
      final response = await _llama.generate(params);
      final raw = response.text.trim();
      if (raw.isEmpty) {
        throw const LocalScamAnalysisException(
          'Empty response from local model.',
        );
      }

      return _parseResponse(raw).copyWith(resolvedLocally: true);
    } on LocalScamAnalysisException {
      rethrow;
    } on Object catch (e, stack) {
      developer.log(
        'Local scam analysis failed',
        name: 'LocalScamAnalysisService',
        error: e,
        stackTrace: stack,
      );
      // A failed decode (e.g. native ggml_abort) can leave the underlying
      // context in a broken state; force a fresh load on the next attempt.
      _modelLoaded = false;
      _loadedFromPath = null;
      throw LocalScamAnalysisException('Local analysis failed: $e');
    }
  }

  Future<void> _ensureModelLoaded(String modelPath) async {
    if (_modelLoaded && _loadedFromPath == modelPath) {
      return;
    }

    // CPU-only inference. Some Android GPUs (Vulkan/OpenCL backends used by
    // llama.cpp) trigger SIGABRT inside ggml during decode when off-loading
    // all layers; falling back to CPU is a small Qwen-0.5B model and runs
    // comfortably without GPU acceleration.
    final loaded = await _llama.loadModel(
      LlamaConfig(
        modelPath: modelPath,
        nThreads: 4,
        nGpuLayers: 0,
        contextSize: 2048,
        batchSize: 256,
        useGpu: false,
        verbose: false,
      ),
    );
    if (!loaded) {
      throw const LocalScamAnalysisException('Failed to load local model.');
    }
    _modelLoaded = true;
    _loadedFromPath = modelPath;
  }

  ScamAnalysis _parseResponse(String raw) {
    final jsonText = _extractJson(raw);
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }
      return ScamAnalysisDto.fromJson(decoded).toEntity();
    } on Object catch (e) {
      throw LocalScamAnalysisException(
        'Could not parse local model response: $e',
      );
    }
  }

  String _extractJson(String raw) {
    final fenceMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      multiLine: true,
    ).firstMatch(raw);
    if (fenceMatch != null) {
      return fenceMatch.group(1)!.trim();
    }

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end > start) {
      return raw.substring(start, end + 1);
    }

    return raw;
  }
}
