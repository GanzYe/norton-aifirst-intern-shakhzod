import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/orchestrate_scam_analysis_usecase.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockScamAnalysisRepository scamRepo;
  late MockPiiRedactionRepository pii;
  late MockVirusTotalRepository vt;
  late MockAbuseIpdbRepository abuse;
  late MockUrlScanRepository urlScan;
  late MockEmlParseRepository eml;
  late MockConnectivityService connectivity;
  late MockLocalScamAnalysisService localLlama;
  late MockModelDownloadService modelDownload;
  late OrchestrateScamAnalysisUseCase useCase;

  const phishingSms =
      'Hi, your DHL parcel is held: please confirm at http://dhl-redelivery.example/track right now.';

  setUp(() {
    scamRepo = MockScamAnalysisRepository();
    pii = MockPiiRedactionRepository();
    vt = MockVirusTotalRepository();
    abuse = MockAbuseIpdbRepository();
    urlScan = MockUrlScanRepository();
    eml = MockEmlParseRepository();
    connectivity = MockConnectivityService();
    localLlama = MockLocalScamAnalysisService();
    modelDownload = MockModelDownloadService();

    when(pii.scrubPii(any)).thenAnswer((inv) async {
      return inv.positionalArguments.first as String;
    });
    when(vt.scanUrl(any)).thenAnswer(
      (_) async => const VirusTotalResult(
        url: 'http://example',
        maliciousCount: 0,
        totalEngines: 76,
      ),
    );
    when(urlScan.submitUrl(any)).thenAnswer(
      (_) async => const UrlScanResult(
        url: 'http://example',
        scanId: 'scan-id-test',
        visibility: 'unlisted',
      ),
    );
    when(abuse.checkIp(any)).thenAnswer(
      (_) async => const AbuseIpdbResult(
        ipAddress: '0.0.0.0',
        abuseConfidenceScore: 0,
        totalReports: 0,
      ),
    );

    useCase = OrchestrateScamAnalysisUseCase(
      scamAnalysisRepository: scamRepo,
      piiRedactionRepository: pii,
      virusTotalRepository: vt,
      abuseIpdbRepository: abuse,
      urlScanRepository: urlScan,
      emlParseRepository: eml,
      buildAugmentedPromptUseCase: const BuildAugmentedPromptUseCase(),
      connectivityService: connectivity,
      localScamAnalysisService: localLlama,
      modelDownloadService: modelDownload,
    );
  });

  group('Input validation', () {
    test('throws when message is empty', () {
      expect(
        () => useCase(
          const SoarAnalysisInput(rawContent: '   ', kind: SoarInputKind.plainText),
        ),
        throwsA(isA<AnalyzeMessageException>()),
      );
    });

    test('throws when message is too short', () {
      expect(
        () => useCase(
          const SoarAnalysisInput(rawContent: 'hi', kind: SoarInputKind.plainText),
        ),
        throwsA(isA<AnalyzeMessageException>()),
      );
    });
  });

  group('Online path → cloud cascade', () {
    setUp(() {
      when(connectivity.isOnline()).thenAnswer((_) async => true);
    });

    test('runs OSINT for URLs, builds master prompt, returns cloud verdict',
        () async {
      when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.dangerous,
          confidence: 90,
          explanation: 'cloud verdict',
        ),
      );

      final result = await useCase(
        const SoarAnalysisInput(
          rawContent: phishingSms,
          kind: SoarInputKind.url,
        ),
      );

      expect(result.riskLevel, RiskLevel.dangerous);
      expect(result.confidence, 90);
      verify(vt.scanUrl(any)).called(1);
      verify(urlScan.submitUrl(any)).called(1);
      verify(scamRepo.analyzeAugmentedPrompt(any)).called(1);
      verifyNever(abuse.checkIp(any));
      verifyNever(localLlama.analyze(any));
    });

    test('checks AbuseIPDB only when input contains an IP', () async {
      when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.suspicious,
          confidence: 70,
          explanation: 'cloud verdict',
        ),
      );

      await useCase(
        const SoarAnalysisInput(
          rawContent: 'Please connect to 203.0.113.7 right away.',
          kind: SoarInputKind.plainText,
        ),
      );

      verify(abuse.checkIp('203.0.113.7')).called(1);
    });

    test('passes scrubbed content to the augmented prompt when incognito is on',
        () async {
      when(pii.scrubPii(any)).thenAnswer((_) async => '<<SCRUBBED>>');
      when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.safe,
          confidence: 80,
          explanation: 'cloud verdict',
        ),
      );

      await useCase(
        const SoarAnalysisInput(
          rawContent: 'Reply to john@example.com',
          kind: SoarInputKind.plainText,
          incognitoEnabled: true,
        ),
      );

      verify(pii.scrubPii(any)).called(1);
      final captured = verify(scamRepo.analyzeAugmentedPrompt(captureAny))
          .captured
          .single as String;
      expect(captured, contains('<<SCRUBBED>>'));
    });

    test('incognito + plain text skips OSINT entirely', () async {
      when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.safe,
          confidence: 80,
          explanation: 'cloud verdict',
        ),
      );

      await useCase(
        const SoarAnalysisInput(
          rawContent: 'Some private chatter between friends.',
          kind: SoarInputKind.plainText,
          incognitoEnabled: true,
        ),
      );

      verifyNever(vt.scanUrl(any));
      verifyNever(abuse.checkIp(any));
      verifyNever(urlScan.submitUrl(any));
    });

    test('falls back to on-device model when both cloud providers fail',
        () async {
      when(scamRepo.analyzeAugmentedPrompt(any))
          .thenThrow(const GeminiDataSourceException('cloud down'));
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(localLlama.analyze(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.suspicious,
          confidence: 65,
          explanation: 'on-device verdict',
          resolvedLocally: true,
        ),
      );

      final result = await useCase(
        const SoarAnalysisInput(
          rawContent: phishingSms,
          kind: SoarInputKind.url,
        ),
      );

      expect(result.riskLevel, RiskLevel.suspicious);
      expect(result.cloudFallback, isTrue);
      expect(result.resolvedLocally, isTrue);
      verify(localLlama.analyze(any)).called(1);
    });

    test('throws AnalyzeMessageException when cloud fails and no local model',
        () async {
      when(scamRepo.analyzeAugmentedPrompt(any))
          .thenThrow(const GeminiDataSourceException('cloud down'));
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => false);

      expect(
        () => useCase(
          const SoarAnalysisInput(
            rawContent: phishingSms,
            kind: SoarInputKind.url,
          ),
        ),
        throwsA(isA<AnalyzeMessageException>()),
      );
    });

    test('OSINT failures are swallowed; cloud call still happens', () async {
      // The orchestrator catches OSINT errors via `.onError(...)` on the
      // returned future, so we must reply with `Future.error` rather than
      // a synchronous `thenThrow`.
      when(vt.scanUrl(any)).thenAnswer(
        (_) => Future.error(
          const VirusTotalRepositoryException('VT down', statusCode: 500),
        ),
      );
      when(urlScan.submitUrl(any)).thenAnswer(
        (_) => Future.error(
          const UrlScanRepositoryException('URLScan down'),
        ),
      );
      when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.suspicious,
          confidence: 50,
          explanation: 'cloud verdict despite osint failures',
        ),
      );

      final result = await useCase(
        const SoarAnalysisInput(
          rawContent: phishingSms,
          kind: SoarInputKind.url,
        ),
      );

      expect(result.confidence, 50);
      verify(scamRepo.analyzeAugmentedPrompt(any)).called(1);
    });
  });

  group('Offline path → on-device Llama', () {
    setUp(() {
      when(connectivity.isOnline()).thenAnswer((_) async => false);
    });

    test('returns on-device verdict when offline and model is available',
        () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(localLlama.analyze(any)).thenAnswer(
        (_) async => const ScamAnalysis(
          riskLevel: RiskLevel.dangerous,
          confidence: 85,
          explanation: 'on-device verdict',
          resolvedLocally: true,
        ),
      );

      final result = await useCase(
        const SoarAnalysisInput(
          rawContent: phishingSms,
          kind: SoarInputKind.plainText,
        ),
      );

      expect(result.riskLevel, RiskLevel.dangerous);
      expect(result.resolvedLocally, isTrue);
      verifyNever(scamRepo.analyzeAugmentedPrompt(any));
    });

    test('returns localModelUnavailable when offline and no model on disk',
        () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => false);

      final result = await useCase(
        const SoarAnalysisInput(
          rawContent: phishingSms,
          kind: SoarInputKind.plainText,
        ),
      );

      expect(result.localModelUnavailable, isTrue);
      verifyNever(localLlama.analyze(any));
    });

    test('returns localAnalysisFailed when offline and Llama throws', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(localLlama.analyze(any)).thenThrow(
        const LocalScamAnalysisException('parse error'),
      );

      final result = await useCase(
        const SoarAnalysisInput(
          rawContent: phishingSms,
          kind: SoarInputKind.plainText,
        ),
      );

      expect(result.localAnalysisFailed, isTrue);
    });
  });
}
