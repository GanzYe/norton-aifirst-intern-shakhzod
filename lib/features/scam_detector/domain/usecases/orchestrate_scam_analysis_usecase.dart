import 'dart:developer' as developer;

import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/analysis_outcome.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/analysis_failure.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/analyze_message_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/cloud_analysis_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/local_analysis_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/exceptions/pii_scrub_failure_exception.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/connectivity_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/local_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/model_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/input_classifier.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/osint_target_extractor.dart';

/// SOAR pipeline: Incognito → PII scrub → concurrent OSINT →
/// augmented cloud prompt. Falls back to local Llama when offline or
/// cloud fails.
class OrchestrateScamAnalysisUseCase {
  const OrchestrateScamAnalysisUseCase({
    required ScamAnalysisRepository scamAnalysisRepository,
    required PiiRedactionRepository piiRedactionRepository,
    required VirusTotalRepository virusTotalRepository,
    required AbuseIpdbRepository abuseIpdbRepository,
    required UrlScanRepository urlScanRepository,
    required EmlParseRepository emlParseRepository,
    required BuildAugmentedPromptUseCase buildAugmentedPromptUseCase,
    required ConnectivityRepository connectivityRepository,
    required LocalAnalysisRepository localAnalysisRepository,
    required ModelRepository modelRepository,
  }) : _scamAnalysisRepository = scamAnalysisRepository,
       _piiRedactionRepository = piiRedactionRepository,
       _virusTotalRepository = virusTotalRepository,
       _abuseIpdbRepository = abuseIpdbRepository,
       _urlScanRepository = urlScanRepository,
       _emlParseRepository = emlParseRepository,
       _buildAugmentedPromptUseCase = buildAugmentedPromptUseCase,
       _connectivityRepository = connectivityRepository,
       _localAnalysisRepository = localAnalysisRepository,
       _modelRepository = modelRepository;

  final ScamAnalysisRepository _scamAnalysisRepository;
  final PiiRedactionRepository _piiRedactionRepository;
  final VirusTotalRepository _virusTotalRepository;
  final AbuseIpdbRepository _abuseIpdbRepository;
  final UrlScanRepository _urlScanRepository;
  final EmlParseRepository _emlParseRepository;
  final BuildAugmentedPromptUseCase _buildAugmentedPromptUseCase;
  final ConnectivityRepository _connectivityRepository;
  final LocalAnalysisRepository _localAnalysisRepository;
  final ModelRepository _modelRepository;

  static const _stage = 'ORCHESTRATOR';

  AnalysisSuccess _success(ScamAnalysis analysis) {
    return AnalysisSuccess(
      analysis.copyWith(pipelineLog: PipelineLog.takeCapture()),
    );
  }

  Future<AnalysisOutcome> call(SoarAnalysisInput input) async {
    PipelineLog.beginCapture();
    try {
      return await _runPipeline(input);
    } on Object {
      PipelineLog.discardCapture();
      rethrow;
    }
  }

  Future<AnalysisOutcome> _runPipeline(SoarAnalysisInput input) async {
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

    final isOnline = await _connectivityRepository.isOnline();
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

    final scrubbed = await _safeScrubPii(
      contentForAnalysis,
      incognitoEnabled: input.incognitoEnabled,
    );

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
      return _success(analysis);
    } on CloudAnalysisExhaustedException catch (cloudError, cloudStack) {
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
        return _success(localResult.copyWith(cloudFallback: true));
      }
      PipelineLog.failure(_stage, cloudError, stackTrace: cloudStack);
      throw const AnalyzeMessageException(
        'Analysis is currently unavailable. Please try again in a moment.',
      );
    }
  }

  Future<AnalysisOutcome> _analyzeOffline({
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

    final scrubbed = await _safeScrubPii(
      contentForAnalysis,
      incognitoEnabled: input.incognitoEnabled,
    );

    final modelReady = await _modelRepository.isModelDownloaded();
    if (!modelReady) {
      PipelineLog.warn(_stage, 'offline and on-device model not downloaded');
      return const LocalModelUnavailable();
    }

    PipelineLog.modelRoute(
      target: 'local',
      model: 'on-device Qwen2 (LLAMA_LOCAL)',
      payload: scrubbed,
    );

    try {
      final result = await _localAnalysisRepository.analyze(scrubbed);
      PipelineLog.done(
        _stage,
        message: 'offline verdict returned',
        context: {
          'riskLevel': result.riskLevel.label,
          'confidence': result.confidence,
        },
      );
      return _success(result);
    } on LocalAnalysisException catch (e, stack) {
      developer.log(
        'Offline local analysis failed; returning AnalysisError',
        name: 'OrchestrateScamAnalysisUseCase',
        error: e,
        stackTrace: stack,
      );
      PipelineLog.failure(_stage, e, stackTrace: stack);
      return AnalysisError(LocalAnalysisFailure(e.message));
    }
  }

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

  // FIXED: [P0] Incognito must fail closed — never send raw content to
  // cloud on scrub error.
  Future<String> _safeScrubPii(
    String content, {
    required bool incognitoEnabled,
  }) async {
    try {
      return await _piiRedactionRepository.scrubPii(content);
    } on Object catch (e, stack) {
      developer.log(
        incognitoEnabled
            ? 'PII redaction failed in Incognito; blocking analysis'
            : 'PII redaction failed; using original content (Incognito off)',
        name: 'OrchestrateScamAnalysisUseCase',
        error: e,
        stackTrace: stack,
      );
      if (incognitoEnabled) {
        throw PiiScrubFailureException(
          const PiiScrubFailure().message,
        );
      }
      return content;
    }
  }

  Future<ScamAnalysis?> _tryLocalFallback(String scrubbed) async {
    if (!await _modelRepository.isModelDownloaded()) {
      return null;
    }
    try {
      return await _localAnalysisRepository.analyze(scrubbed);
    } on LocalAnalysisException {
      return null;
    }
  }

  Future<ThreatIntelSnapshot> _gatherThreatIntel({
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
          _virusTotalRepository.scanUrl(url).then((r) {
            vtResult = r;
          }).catchError((Object error, StackTrace stack) {
            _logOsintFailure('OSINT.VT', error, stack);
          }),
        )
        ..add(
          _urlScanRepository.submitUrl(url).then((r) {
            urlScanResult = r;
          }).catchError((Object error, StackTrace stack) {
            _logOsintFailure('OSINT.URLScan', error, stack);
          }),
        );
    }

    if (ip != null) {
      futures.add(
        _abuseIpdbRepository.checkIp(ip).then((r) {
          abuseResult = r;
        }).catchError((Object error, StackTrace stack) {
          _logOsintFailure('OSINT.AbuseIPDB', error, stack);
        }),
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

  // FIXED: [P0] OSINT failures were silently swallowed; now logged at WARN.
  void _logOsintFailure(String stage, Object error, StackTrace stack) {
    PipelineLog.warn(
      stage,
      'lookup failed; continuing without this intel',
      error: error,
    );
    developer.log(
      'OSINT lookup failed',
      name: 'OrchestrateScamAnalysisUseCase',
      error: error,
      stackTrace: stack,
    );
  }
}
