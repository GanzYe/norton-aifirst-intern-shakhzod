import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';
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
class LocalScamAnalysisService {
  LocalScamAnalysisService({
    required FlutterLlama llama,
    required String modelPath,
  })  : _llama = llama,
        _modelPath = modelPath;

  final FlutterLlama _llama;
  final String _modelPath;

  bool _modelLoaded = false;

  bool get isModelReady => _modelPath.isNotEmpty;

  Future<ScamAnalysis> analyze(String message) async {
    if (!isModelReady) {
      throw const LocalScamAnalysisException('Local model path is not set.');
    }

    try {
      await _ensureModelLoaded();
      final params = GenerationParams(
        prompt: '$_scamAnalysisSystemPrompt\n\nAnalyze this message:\n\n$message',
        temperature: 0.2,
        topP: 0.9,
        topK: 40,
        maxTokens: 512,
        repeatPenalty: 1.1,
      );

      final buffer = StringBuffer();
      await for (final token in _llama.generateStream(params)) {
        buffer.write(token);
      }

      final raw = buffer.toString().trim();
      if (raw.isEmpty) {
        throw const LocalScamAnalysisException('Empty response from local model.');
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
      throw LocalScamAnalysisException('Local analysis failed: $e');
    }
  }

  Future<void> _ensureModelLoaded() async {
    if (_modelLoaded) {
      return;
    }

    final loaded = await _llama.loadModel(
      LlamaConfig(
        modelPath: _modelPath,
        nThreads: 4,
        nGpuLayers: -1,
        contextSize: 2048,
        batchSize: 512,
        useGpu: true,
        verbose: false,
      ),
    );
    if (!loaded) {
      throw const LocalScamAnalysisException('Failed to load local model.');
    }
    _modelLoaded = true;
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
