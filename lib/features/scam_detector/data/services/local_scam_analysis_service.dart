import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/llama_native_probe.dart';
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
/// Path is resolved lazily from [ModelDownloadService] at each call, and a
/// native-health probe gates any call into the buggy `flutter_llama` 1.1.2
/// plugin to avoid `UnsatisfiedLinkError` crashes on devices without the
/// expected `.so` files.
class LocalScamAnalysisService {
  LocalScamAnalysisService({
    required FlutterLlama llama,
    required ModelDownloadService modelDownloadService,
    required LlamaNativeProbe nativeProbe,
  })  : _llama = llama,
        _modelDownload = modelDownloadService,
        _nativeProbe = nativeProbe;

  static const _loadTimeout = Duration(seconds: 45);
  static const _generateTimeout = Duration(minutes: 2);

  final FlutterLlama _llama;
  final ModelDownloadService _modelDownload;
  final LlamaNativeProbe _nativeProbe;

  bool _modelLoaded = false;
  String? _loadedFromPath;

  Future<bool> isUsable() async {
    if (!await _modelDownload.isModelDownloaded()) return false;
    return _nativeProbe.isAvailable();
  }

  Future<ScamAnalysis> analyze(String message) async {
    if (!await _modelDownload.isModelDownloaded()) {
      throw const LocalScamAnalysisException(
        'Local model is not downloaded.',
      );
    }
    if (!await _nativeProbe.isAvailable()) {
      throw const LocalScamAnalysisException(
        'On-device AI engine is not available on this device.',
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

      // Non-streaming generate() avoids the EventChannel race in
      // flutter_llama 1.1.2 (NO_EVENT_SINK). Timeout guards against the
      // native worker dying silently mid-flight.
      final response = await _llama.generate(params).timeout(_generateTimeout);
      final raw = response.text.trim();
      if (raw.isEmpty) {
        throw const LocalScamAnalysisException(
          'Empty response from local model.',
        );
      }

      return _parseResponse(raw).copyWith(resolvedLocally: true);
    } on LocalScamAnalysisException {
      _resetLoadState();
      rethrow;
    } on TimeoutException catch (e, stack) {
      developer.log(
        'Local model inference timed out',
        name: 'LocalScamAnalysisService',
        error: e,
        stackTrace: stack,
      );
      _resetLoadState();
      throw const LocalScamAnalysisException(
        'On-device analysis took too long. Please try again.',
      );
    } on Object catch (e, stack) {
      developer.log(
        'Local scam analysis failed',
        name: 'LocalScamAnalysisService',
        error: e,
        stackTrace: stack,
      );
      _resetLoadState();
      throw const LocalScamAnalysisException(
        "Couldn't run on-device analysis. Please try again.",
      );
    }
  }

  Future<void> _ensureModelLoaded(String modelPath) async {
    if (_modelLoaded && _loadedFromPath == modelPath) {
      return;
    }

    // CPU-only inference. flutter_llama's Vulkan/OpenCL backends trigger
    // ggml_abort during decode on a number of Android devices.
    final loaded = await _llama
        .loadModel(
          LlamaConfig(
            modelPath: modelPath,
            nThreads: 4,
            nGpuLayers: 0,
            contextSize: 2048,
            batchSize: 256,
            useGpu: false,
            verbose: false,
          ),
        )
        .timeout(_loadTimeout);
    if (!loaded) {
      throw const LocalScamAnalysisException('Failed to load local model.');
    }
    _modelLoaded = true;
    _loadedFromPath = modelPath;
  }

  void _resetLoadState() {
    _modelLoaded = false;
    _loadedFromPath = null;
  }

  ScamAnalysis _parseResponse(String raw) {
    final jsonText = _extractJson(raw);
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }
      return ScamAnalysisDto.fromJson(decoded).toEntity();
    } on Object catch (e, stack) {
      developer.log(
        'Could not parse local model response',
        name: 'LocalScamAnalysisService',
        error: e,
        stackTrace: stack,
      );
      throw const LocalScamAnalysisException(
        "Couldn't read the on-device model response.",
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
