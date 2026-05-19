import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/llama_native_probe.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';

// Qwen2-Instruct expects the ChatML template. Skipping it on a 0.5B model
// makes it ignore "respond with JSON" instructions and emit free-form prose.
const _imStart = '<|im_start|>';
const _imEnd = '<|im_end|>';

const _systemPrompt = '''
You are a cybersecurity classifier. Given one message, decide if it is SAFE, SUSPICIOUS, or DANGEROUS, and reply with ONE JSON object only, no prose, no markdown fences.

Schema (all keys required):
{"risk_level":"SAFE"|"SUSPICIOUS"|"DANGEROUS","confidence":0-100,"explanation":"one or two short sentences"}

Definitions:
- SAFE: legitimate or low-risk content.
- SUSPICIOUS: urgency, impersonation, odd links, prize/lottery patterns.
- DANGEROUS: clear phishing, credential theft, malware links, or financial fraud.''';

const _fewShotUser =
    'Your account has been suspended. Click http://secure-login.example.tk to reactivate within 24h or lose access.';
const _fewShotAssistant =
    '{"risk_level":"DANGEROUS","confidence":92,"explanation":"Urgent account-suspension wording paired with a suspicious .tk login link is a classic phishing pattern aimed at stealing credentials."}';

// Keep the user message comfortably inside the 2048-token context so the
// native llama backend doesn't `ggml_abort` mid-decode on long inputs.
const _maxInputChars = 1600;

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

  static const _stage = 'LLAMA_LOCAL';
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
    PipelineLog.start(_stage, context: {'messageChars': message.length});
    if (!await _modelDownload.isModelDownloaded()) {
      const exc = LocalScamAnalysisException(
        'Local model is not downloaded.',
      );
      PipelineLog.failure(_stage, exc, message: 'model file missing');
      throw exc;
    }
    if (!await _nativeProbe.isAvailable()) {
      const exc = LocalScamAnalysisException(
        'On-device AI engine is not available on this device.',
      );
      PipelineLog.failure(_stage, exc, message: 'native libs missing');
      throw exc;
    }

    try {
      final modelPath = await _modelDownload.getModelPath();
      await _ensureModelLoaded(modelPath);

      final prompt = _buildChatMlPrompt(message);
      PipelineLog.info(
        _stage,
        'generating verdict',
        context: {'promptChars': prompt.length, 'maxTokens': 220},
      );

      final params = GenerationParams(
        prompt: prompt,
        // Lower temperature + tight top_p keeps the small model honest on
        // schema and prevents it from drifting into free-form prose.
        temperature: 0.1,
        topP: 0.8,
        topK: 30,
        maxTokens: 220,
        repeatPenalty: 1.1,
        stopSequences: const [_imEnd, '<|endoftext|>'],
      );

      // Non-streaming generate() avoids the EventChannel race in
      // flutter_llama 1.1.2 (NO_EVENT_SINK). Timeout guards against the
      // native worker dying silently mid-flight.
      final response = await _llama.generate(params).timeout(_generateTimeout);
      final raw = response.text.trim();
      if (raw.isEmpty) {
        const exc = LocalScamAnalysisException(
          'Empty response from local model.',
        );
        PipelineLog.failure(_stage, exc);
        throw exc;
      }

      final parsed = _parseResponse(raw).copyWith(resolvedLocally: true);
      PipelineLog.done(
        _stage,
        message: 'verdict returned',
        context: {
          'riskLevel': parsed.riskLevel.label,
          'confidence': parsed.confidence,
        },
      );
      return parsed;
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
      const exc = LocalScamAnalysisException(
        'On-device analysis took too long. Please try again.',
      );
      PipelineLog.failure(_stage, exc, stackTrace: stack, message: 'timeout');
      _resetLoadState();
      throw exc;
    } on Object catch (e, stack) {
      developer.log(
        'Local scam analysis failed',
        name: 'LocalScamAnalysisService',
        error: e,
        stackTrace: stack,
      );
      PipelineLog.failure(_stage, e, stackTrace: stack);
      _resetLoadState();
      throw const LocalScamAnalysisException(
        "Couldn't run on-device analysis. Please try again.",
      );
    }
  }

  Future<void> _ensureModelLoaded(String modelPath) async {
    if (_modelLoaded && _loadedFromPath == modelPath) {
      PipelineLog.info(_stage, 'model already loaded; reusing context');
      return;
    }

    PipelineLog.info(
      _stage,
      'loading GGUF model into CPU backend',
      context: {'contextSize': 2048, 'batchSize': 256, 'threads': 4},
    );
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
    PipelineLog.info(_stage, 'model loaded');
  }

  void _resetLoadState() {
    _modelLoaded = false;
    _loadedFromPath = null;
  }

  String _buildChatMlPrompt(String message) {
    final safe = _truncateForContext(message);
    final buffer = StringBuffer()
      ..writeln('${_imStart}system')
      ..writeln(_systemPrompt)
      ..writeln(_imEnd)
      ..writeln('${_imStart}user')
      ..writeln('Analyze this message:')
      ..writeln(_fewShotUser)
      ..writeln(_imEnd)
      ..writeln('${_imStart}assistant')
      ..writeln(_fewShotAssistant)
      ..writeln(_imEnd)
      ..writeln('${_imStart}user')
      ..writeln('Analyze this message:')
      ..writeln(safe)
      ..writeln(_imEnd)
      ..write('${_imStart}assistant\n');
    return buffer.toString();
  }

  String _truncateForContext(String message) {
    final collapsed = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= _maxInputChars) return collapsed;
    return '${collapsed.substring(0, _maxInputChars)}…';
  }

  /// Exposed for tests so the JSON/natural-language parse logic can be
  /// exercised without bringing up the `flutter_llama` native plugin.
  @visibleForTesting
  ScamAnalysis parseModelResponseForTest(String raw) => _parseResponse(raw);

  ScamAnalysis _parseResponse(String raw) {
    final cleaned = _stripChatMlArtifacts(raw);

    final fromJson = _tryParseJson(cleaned);
    if (fromJson != null) return fromJson;

    // The 0.5B model regularly drops the JSON contract and emits
    // `LABEL: explanation` instead — recover the verdict from that shape
    // rather than failing the whole offline path.
    final fromText = _tryParseLabelled(cleaned);
    if (fromText != null) {
      developer.log(
        'Local model response was not JSON; recovered verdict from text',
        name: 'LocalScamAnalysisService',
      );
      return fromText;
    }

    developer.log(
      'Could not parse local model response',
      name: 'LocalScamAnalysisService',
      error: 'Unparseable response: '
          '${cleaned.substring(0, cleaned.length.clamp(0, 240))}',
    );
    throw const LocalScamAnalysisException(
      "Couldn't read the on-device model response.",
    );
  }

  String _stripChatMlArtifacts(String raw) {
    var text = raw;
    final endIdx = text.indexOf(_imEnd);
    if (endIdx != -1) text = text.substring(0, endIdx);
    return text
        .replaceAll(_imStart, '')
        .replaceAll('<|endoftext|>', '')
        .replaceFirst(RegExp(r'^\s*assistant\s*'), '')
        .trim();
  }

  ScamAnalysis? _tryParseJson(String text) {
    final candidate = _extractJsonObject(text);
    if (candidate == null) return null;
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is! Map<String, dynamic>) return null;
      return ScamAnalysisDto.fromJson(decoded).toEntity();
    } on Object {
      return null;
    }
  }

  String? _extractJsonObject(String raw) {
    final fenceMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      multiLine: true,
    ).firstMatch(raw);
    if (fenceMatch != null) {
      final inner = fenceMatch.group(1)?.trim();
      if (inner != null && inner.isNotEmpty) return inner;
    }

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end > start) {
      return raw.substring(start, end + 1);
    }
    return null;
  }

  /// Recovers a verdict from a free-form response like
  /// `SUSPICIOUS: The message appears to be a phishing attempt...`
  /// or `Risk: DANGEROUS — credential theft attempt`.
  ScamAnalysis? _tryParseLabelled(String text) {
    if (text.isEmpty) return null;

    final upper = text.toUpperCase();
    final levels = {
      'DANGEROUS': RiskLevel.dangerous,
      'SUSPICIOUS': RiskLevel.suspicious,
      'SAFE': RiskLevel.safe,
    };

    RiskLevel? matched;
    var matchIndex = -1;
    for (final entry in levels.entries) {
      final idx = upper.indexOf(entry.key);
      if (idx != -1 && (matchIndex == -1 || idx < matchIndex)) {
        matched = entry.value;
        matchIndex = idx;
      }
    }
    if (matched == null) return null;

    final afterLabel = text
        .substring(matchIndex + matched.label.length)
        .replaceFirst(RegExp(r'^[\s:\-–—,.]+'), '')
        .trim();
    final explanation = afterLabel.isNotEmpty
        ? _firstSentences(afterLabel, 3)
        : 'On-device model returned an abbreviated verdict.';

    final confidence = switch (matched) {
      RiskLevel.dangerous => 80,
      RiskLevel.suspicious => 65,
      RiskLevel.safe => 70,
    };

    return ScamAnalysis(
      riskLevel: matched,
      confidence: confidence,
      explanation: explanation,
    );
  }

  String _firstSentences(String text, int maxSentences) {
    final matches = RegExp('[^.!?]+[.!?]').allMatches(text).take(maxSentences);
    if (matches.isEmpty) {
      return text.length > 240 ? '${text.substring(0, 240).trim()}…' : text;
    }
    return matches.map((m) => m.group(0)!.trim()).join(' ');
  }
}
