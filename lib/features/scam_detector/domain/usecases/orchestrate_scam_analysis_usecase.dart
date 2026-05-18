import 'package:scam_message_detector/features/scam_detector/domain/entities/email_auth_alignment.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/input_classifier.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/osint_target_extractor.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';

/// SOAR pipeline: Incognito → PII scrub → concurrent OSINT → augmented Gemini prompt.
class OrchestrateScamAnalysisUseCase {
  const OrchestrateScamAnalysisUseCase({
    required ScamAnalysisRepository scamAnalysisRepository,
    required PiiRedactionRepository piiRedactionRepository,
    required VirusTotalRepository virusTotalRepository,
    required AbuseIpdbRepository abuseIpdbRepository,
    required UrlScanRepository urlScanRepository,
    required EmlParseRepository emlParseRepository,
    required BuildAugmentedPromptUseCase buildAugmentedPromptUseCase,
  })  : _scamAnalysisRepository = scamAnalysisRepository,
        _piiRedactionRepository = piiRedactionRepository,
        _virusTotalRepository = virusTotalRepository,
        _abuseIpdbRepository = abuseIpdbRepository,
        _urlScanRepository = urlScanRepository,
        _emlParseRepository = emlParseRepository,
        _buildAugmentedPromptUseCase = buildAugmentedPromptUseCase;

  final ScamAnalysisRepository _scamAnalysisRepository;
  final PiiRedactionRepository _piiRedactionRepository;
  final VirusTotalRepository _virusTotalRepository;
  final AbuseIpdbRepository _abuseIpdbRepository;
  final UrlScanRepository _urlScanRepository;
  final EmlParseRepository _emlParseRepository;
  final BuildAugmentedPromptUseCase _buildAugmentedPromptUseCase;

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

    final skipOsint =
        input.incognitoEnabled && kind == SoarInputKind.plainText;

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

    return _scamAnalysisRepository.analyzeAugmentedPrompt(masterPrompt);
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
      futures.add(
        _virusTotalRepository.scanUrl(url).then((r) {
          vtResult = r;
        }).onError((_, _) {}),
      );
      futures.add(
        _urlScanRepository.submitUrl(url).then((r) {
          urlScanResult = r;
        }).onError((_, _) {}),
      );
    }

    if (ip != null) {
      futures.add(
        _abuseIpdbRepository.checkIp(ip).then((r) {
          abuseResult = r;
        }).onError((_, _) {}),
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
