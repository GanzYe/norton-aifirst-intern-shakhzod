import 'dart:developer' as developer;

import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/connectivity_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/input_classifier.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/osint_target_extractor.dart';

/// SOAR pipeline: Incognito → PII scrub → concurrent OSINT →
/// augmented Gemini prompt. Falls back to local Llama when the device is
/// offline or the cloud API is unavailable (e.g. quota/rate-limit).
class OrchestrateScamAnalysisUseCase {
  const OrchestrateScamAnalysisUseCase({
    required ScamAnalysisRepository scamAnalysisRepository,
    required PiiRedactionRepository piiRedactionRepository,
    required VirusTotalRepository virusTotalRepository,
    required AbuseIpdbRepository abuseIpdbRepository,
    required UrlScanRepository urlScanRepository,
    required EmlParseRepository emlParseRepository,
    required BuildAugmentedPromptUseCase buildAugmentedPromptUseCase,
    required ConnectivityService connectivityService,
    required LocalScamAnalysisService localScamAnalysisService,
    required ModelDownloadService modelDownloadService,
  }) : _scamAnalysisRepository = scamAnalysisRepository,
       _piiRedactionRepository = piiRedactionRepository,
       _virusTotalRepository = virusTotalRepository,
       _abuseIpdbRepository = abuseIpdbRepository,
       _urlScanRepository = urlScanRepository,
       _emlParseRepository = emlParseRepository,
       _buildAugmentedPromptUseCase = buildAugmentedPromptUseCase,
       _connectivityService = connectivityService,
       _localScamAnalysisService = localScamAnalysisService,
       _modelDownloadService = modelDownloadService;

  final ScamAnalysisRepository _scamAnalysisRepository;
  final PiiRedactionRepository _piiRedactionRepository;
  final VirusTotalRepository _virusTotalRepository;
  final AbuseIpdbRepository _abuseIpdbRepository;
  final UrlScanRepository _urlScanRepository;
  final EmlParseRepository _emlParseRepository;
  final BuildAugmentedPromptUseCase _buildAugmentedPromptUseCase;
  final ConnectivityService _connectivityService;
  final LocalScamAnalysisService _localScamAnalysisService;
  final ModelDownloadService _modelDownloadService;

  static const _stage = 'ORCHESTRATOR';

  ScamAnalysis _attachPipelineLog(ScamAnalysis analysis) {
    return analysis.copyWith(pipelineLog: PipelineLog.takeCapture());
  }

  Future<ScamAnalysis> call(SoarAnalysisInput input) async {
    PipelineLog.beginCapture();
    try {
      return await _runPipeline(input);
    } on Object {
      PipelineLog.discardCapture();
      rethrow;
    }
  }

  Future<ScamAnalysis> _runPipeline(SoarAnalysisInput input) async {
    final trimmed = input.rawContent.trim();
    PipelineLog.start(
      _stage,
      context: {
        'inputKind': input.kind.name,
        'incognito': input.incognitoEnabled,
        'inputChars': trimmed.length,
      },
    );
    if (trimmed.isEmpty) {
      throw const AnalyzeMessageException('Please enter a message to analyze.');
    }
    if (trimmed.length < 3) {
      throw const AnalyzeMessageException(
        'Message is too short. Provide more context for analysis.',
      );
    }

    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      PipelineLog.info(_stage, 'offline; routing to on-device path');
      return _analyzeOffline(input: input, trimmed: trimmed);
    }

    final kind = input.kind == SoarInputKind.eml && input.emlRawContent != null
        ? SoarInputKind.eml
        : InputClassifier.classify(trimmed);
    PipelineLog.info('CLASSIFY', 'input kind=${kind.name}');

    EmailAuthAlignment? emailAuth;
    var contentForAnalysis = trimmed;

    if (kind == SoarInputKind.eml) {
      PipelineLog.start('EML_PARSE');
      final emlRaw = input.emlRawContent ?? trimmed;
      final parsed = _safeParseEml(emlRaw);
      emailAuth = parsed?.emailAuth;
      contentForAnalysis = (parsed != null && parsed.bodyPreview.isNotEmpty)
          ? parsed.bodyPreview
          : emlRaw;
      PipelineLog.done(
        'EML_PARSE',
        message: parsed != null ? 'parsed OK' : 'falling back to raw text',
        context: {
          'bodyChars': contentForAnalysis.length,
          'hasAuth': emailAuth != null,
        },
      );
    }

    final scrubbed = input.incognitoEnabled
        ? await _safeScrubPii(contentForAnalysis)
        : contentForAnalysis;

    final skipOsint = input.incognitoEnabled && kind == SoarInputKind.plainText;

    final targets = OsintTargetExtractor.extract(contentForAnalysis);
    PipelineLog.info(
      _stage,
      'OSINT targets extracted',
      context: {'url': targets.primaryUrl, 'ip': targets.primaryIp},
    );
    ThreatIntelSnapshot intel;

    if (skipOsint) {
      PipelineLog.info(_stage, 'OSINT skipped (incognito + plain text)');
      intel = ThreatIntelSnapshot(
        emailAuth: emailAuth,
        osintSkippedDueToIncognito: true,
      );
    } else {
      intel = await _gatherThreatIntel(
        kind: kind,
        targets: targets,
        emailAuth: emailAuth,
      );
    }

    PipelineLog.start('PROMPT');
    final masterPrompt = _buildAugmentedPromptUseCase(
      scrubbedInput: scrubbed,
      intel: intel,
    );
    PipelineLog.done(
      'PROMPT',
      message: 'augmented master prompt assembled',
      context: {'promptChars': masterPrompt.length},
    );

    PipelineLog.modelRoute(
      target: 'regional',
      model: 'GROQ→GEMINI cloud cascade',
      payload: masterPrompt,
    );

    try {
      final analysis = await _scamAnalysisRepository.analyzeAugmentedPrompt(
        masterPrompt,
      );
      PipelineLog.done(
        _stage,
        message: 'cloud verdict returned',
        context: {
          'riskLevel': analysis.riskLevel.label,
          'confidence': analysis.confidence,
        },
      );
      return _attachPipelineLog(analysis);
    } on GeminiDataSourceException catch (cloudError, cloudStack) {
      developer.log(
        'Cloud analysis exhausted; attempting on-device fallback.',
        name: 'OrchestrateScamAnalysisUseCase',
        error: cloudError,
        stackTrace: cloudStack,
      );
      PipelineLog.warn(
        _stage,
        'cloud exhausted; trying on-device fallback',
        error: cloudError,
      );
      PipelineLog.modelRoute(
        target: 'local',
        model: 'on-device Qwen2.5-1.5B (LLAMA_LOCAL)',
        payload: scrubbed,
      );
      final localResult = await _tryLocalFallback(scrubbed);
      if (localResult != null) {
        PipelineLog.done(
          _stage,
          message: 'served by on-device fallback after cloud failure',
        );
        return _attachPipelineLog(
          localResult.copyWith(cloudFallback: true),
        );
      }
      PipelineLog.failure(_stage, cloudError, stackTrace: cloudStack);
      throw const AnalyzeMessageException(
        'Analysis is currently unavailable. Please try again in a moment.',
      );
    }
  }

  Future<ScamAnalysis> _analyzeOffline({
    required SoarAnalysisInput input,
    required String trimmed,
  }) async {
    final kind = input.kind == SoarInputKind.eml && input.emlRawContent != null
        ? SoarInputKind.eml
        : InputClassifier.classify(trimmed);

    var contentForAnalysis = trimmed;

    if (kind == SoarInputKind.eml) {
      final emlRaw = input.emlRawContent ?? trimmed;
      final parsed = _safeParseEml(emlRaw);
      contentForAnalysis = (parsed != null && parsed.bodyPreview.isNotEmpty)
          ? parsed.bodyPreview
          : emlRaw;
    }

    final scrubbed = input.incognitoEnabled
        ? await _safeScrubPii(contentForAnalysis)
        : contentForAnalysis;

    final modelReady = await _modelDownloadService.isModelDownloaded();
    if (!modelReady) {
      PipelineLog.warn(_stage, 'offline and on-device model not downloaded');
      return _attachPipelineLog(
        const ScamAnalysis(
          riskLevel: RiskLevel.safe,
          confidence: 0,
          explanation: '',
          localModelUnavailable: true,
        ),
      );
    }

    PipelineLog.modelRoute(
      target: 'local',
      model: 'on-device Qwen2 (LLAMA_LOCAL)',
      payload: scrubbed,
    );

    try {
      final result = await _localScamAnalysisService.analyze(scrubbed);
      PipelineLog.done(
        _stage,
        message: 'offline verdict returned',
        context: {
          'riskLevel': result.riskLevel.label,
          'confidence': result.confidence,
        },
      );
      return _attachPipelineLog(result);
    } on LocalScamAnalysisException catch (e, stack) {
      // Offline + model is on disk but analysis still failed (parse error,
      // OOM, native crash, etc.). Surface a graceful flagged result instead
      // of leaking a raw platform exception to the UI.
      developer.log(
        'Offline local analysis failed; returning flagged result',
        name: 'OrchestrateScamAnalysisUseCase',
        error: e,
        stackTrace: stack,
      );
      PipelineLog.failure(_stage, e, stackTrace: stack);
      return _attachPipelineLog(
        const ScamAnalysis(
          riskLevel: RiskLevel.safe,
          confidence: 0,
          explanation: '',
          localAnalysisFailed: true,
        ),
      );
    }
  }

  /// Best-effort EML parse. Returns `null` when the input isn't a valid MIME
  /// message so the caller can fall back to treating it as plain text.
  ParsedEmlContent? _safeParseEml(String emlRaw) {
    try {
      return _emlParseRepository.parse(emlRaw);
    } on Object catch (e, stack) {
      developer.log(
        'EML parse failed; treating as plain text',
        name: 'OrchestrateScamAnalysisUseCase',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<String> _safeScrubPii(String content) async {
    try {
      return await _piiRedactionRepository.scrubPii(content);
    } on Object catch (e, stack) {
      developer.log(
        'PII redaction failed; sending original content',
        name: 'OrchestrateScamAnalysisUseCase',
        error: e,
        stackTrace: stack,
      );
      return content;
    }
  }

  /// Best-effort local analysis when the cloud path fails mid-flight.
  /// Returns null when the model isn't ready or local analysis errors —
  /// the caller then propagates the original cloud error.
  Future<ScamAnalysis?> _tryLocalFallback(String scrubbed) async {
    if (!await _modelDownloadService.isModelDownloaded()) {
      return null;
    }
    try {
      return await _localScamAnalysisService.analyze(scrubbed);
    } on LocalScamAnalysisException {
      return null;
    }
  }

  Future<ThreatIntelSnapshot> _gatherThreatIntel({
    required SoarInputKind kind,
    required OsintTargets targets,
    EmailAuthAlignment? emailAuth,
  }) async {
    VirusTotalResult? vtResult;
    AbuseIpdbResult? abuseResult;
    UrlScanResult? urlScanResult;

    final url = targets.primaryUrl;
    final ip = targets.primaryIp;

    final futures = <Future<void>>[];

    if (url != null) {
      futures
        ..add(
          _virusTotalRepository
              .scanUrl(url)
              .then((r) {
                vtResult = r;
              })
              .onError((_, _) {}),
        )
        ..add(
          _urlScanRepository
              .submitUrl(url)
              .then((r) {
                urlScanResult = r;
              })
              .onError((_, _) {}),
        );
    }

    if (ip != null) {
      futures.add(
        _abuseIpdbRepository
            .checkIp(ip)
            .then((r) {
              abuseResult = r;
            })
            .onError((_, _) {}),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    return ThreatIntelSnapshot(
      virusTotal: vtResult,
      abuseIpdb: abuseResult,
      urlScan: urlScanResult,
      emailAuth: emailAuth,
    );
  }
}
