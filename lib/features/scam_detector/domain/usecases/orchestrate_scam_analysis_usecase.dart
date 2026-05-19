import 'dart:developer' as developer;

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
  })  : _scamAnalysisRepository = scamAnalysisRepository,
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

  Future<ScamAnalysis> call(SoarAnalysisInput input) async {
    final trimmed = input.rawContent.trim();
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
      return _analyzeOffline(input: input, trimmed: trimmed);
    }

    final kind = input.kind == SoarInputKind.eml && input.emlRawContent != null
        ? SoarInputKind.eml
        : InputClassifier.classify(trimmed);

    EmailAuthAlignment? emailAuth;
    var contentForAnalysis = trimmed;

    if (kind == SoarInputKind.eml) {
      final emlRaw = input.emlRawContent ?? trimmed;
      final parsed = _emlParseRepository.parse(emlRaw);
      emailAuth = parsed.emailAuth;
      contentForAnalysis = parsed.bodyPreview.isNotEmpty
          ? parsed.bodyPreview
          : emlRaw;
    }

    final scrubbed = input.incognitoEnabled
        ? await _piiRedactionRepository.scrubPii(contentForAnalysis)
        : contentForAnalysis;

    final skipOsint = input.incognitoEnabled && kind == SoarInputKind.plainText;

    final targets = OsintTargetExtractor.extract(contentForAnalysis);
    ThreatIntelSnapshot intel;

    if (skipOsint) {
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

    final masterPrompt = _buildAugmentedPromptUseCase(
      scrubbedInput: scrubbed,
      intel: intel,
    );

    try {
      return await _scamAnalysisRepository.analyzeAugmentedPrompt(masterPrompt);
    } on GeminiDataSourceException {
      final localResult = await _tryLocalFallback(scrubbed);
      if (localResult != null) {
        return localResult.copyWith(cloudFallback: true);
      }
      rethrow;
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
      final parsed = _emlParseRepository.parse(emlRaw);
      contentForAnalysis = parsed.bodyPreview.isNotEmpty
          ? parsed.bodyPreview
          : emlRaw;
    }

    final scrubbed = input.incognitoEnabled
        ? await _piiRedactionRepository.scrubPii(contentForAnalysis)
        : contentForAnalysis;

    final modelReady = await _modelDownloadService.isModelDownloaded();
    if (!modelReady) {
      return const ScamAnalysis(
        riskLevel: RiskLevel.safe,
        confidence: 0,
        explanation: '',
        localModelUnavailable: true,
      );
    }

    try {
      return await _localScamAnalysisService.analyze(scrubbed);
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
      return const ScamAnalysis(
        riskLevel: RiskLevel.safe,
        confidence: 0,
        explanation: '',
        localAnalysisFailed: true,
      );
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
