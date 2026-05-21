import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/analysis_outcome.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/threat_intel_snapshot.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/orchestrate_scam_analysis_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_message_risk_profile.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  group('ExampleMessages catalog', () {
    test('has exactly six samples: 2 safe, 2 suspicious, 2 dangerous', () {
      expect(ExampleMessages.samples, hasLength(6));
      expect(ExampleMessages.withRisk(RiskLevel.safe), hasLength(2));
      expect(ExampleMessages.withRisk(RiskLevel.suspicious), hasLength(2));
      expect(ExampleMessages.withRisk(RiskLevel.dangerous), hasLength(2));
    });

    test('titles are unique and bodies are long enough to analyze', () {
      final titles = ExampleMessages.samples.map((s) => s.title).toList();
      expect(titles.toSet(), hasLength(6));
      for (final sample in ExampleMessages.samples) {
        expect(sample.body.trim().length, greaterThanOrEqualTo(40));
        expect(
          sample.title.toUpperCase(),
          startsWith(sample.expectedRisk.label),
        );
      }
    });

    test('heuristic profile matches expected tier for every sample', () {
      for (final sample in ExampleMessages.samples) {
        expect(
          ExampleMessageRiskProfile.matchesExpected(sample),
          isTrue,
          reason:
              '${sample.title} classified as '
              '${ExampleMessageRiskProfile.classify(sample.body).label} '
              'but expected ${sample.expectedRisk.label}',
        );
      }
    });

    test('suspicious samples avoid dangerous-only phishing signals', () {
      for (final sample in ExampleMessages.withRisk(RiskLevel.suspicious)) {
        final lower = sample.body.toLowerCase();
        expect(lower, isNot(contains('bit.ly/')));
        expect(lower, isNot(contains('.xyz/')));
        expect(lower, isNot(contains('verify immediately at http')));
        expect(lower, isNot(contains(r'won $1,000,000')));
        expect(lower, isNot(contains('account will be suspended')));
      }
    });

    test('suspicious samples include SUSPICIOUS-tier narrative cues', () {
      final signIn = ExampleMessages.withRisk(RiskLevel.suspicious).first;
      final billing = ExampleMessages.withRisk(RiskLevel.suspicious).last;

      expect(signIn.body.toLowerCase(), contains('microsoft'));
      expect(signIn.body.toLowerCase(), contains('sign-in'));

      expect(billing.body.toLowerCase(), contains('t-mobile'));
      expect(billing.body.toLowerCase(), contains('past-due'));
    });

    test('dangerous samples include high-confidence scam markers', () {
      final bank = ExampleMessages.withRisk(RiskLevel.dangerous).first;
      final prize = ExampleMessages.withRisk(RiskLevel.dangerous).last;

      expect(bank.body.toLowerCase(), contains('.xyz/'));
      expect(bank.body.toLowerCase(), contains('suspended'));

      expect(prize.body.toLowerCase(), contains('bit.ly/'));
      expect(prize.body, contains(r'$1,000,000'));
    });
  });

  group('ExampleMessages orchestrator wiring', () {
    late MockScamAnalysisRepository scamRepo;
    late MockPiiRedactionRepository pii;
    late MockConnectivityRepository connectivity;
    late MockVirusTotalRepository vt;
    late MockUrlScanRepository urlScan;
    late OrchestrateScamAnalysisUseCase useCase;

    setUp(() {
      scamRepo = MockScamAnalysisRepository();
      pii = MockPiiRedactionRepository();
      connectivity = MockConnectivityRepository();
      vt = MockVirusTotalRepository();
      urlScan = MockUrlScanRepository();

      when(connectivity.isOnline()).thenAnswer((_) async => true);
      when(pii.scrubPii(any)).thenAnswer((inv) async {
        return inv.positionalArguments.first as String;
      });
      when(vt.scanUrl(any)).thenAnswer(
        (_) async => const VirusTotalResult(
          url: 'http://example.test',
          maliciousCount: 0,
          totalEngines: 76,
        ),
      );
      when(urlScan.submitUrl(any)).thenAnswer(
        (_) async => const UrlScanResult(
          url: 'http://example.test',
          scanId: 'scan-id',
          visibility: 'unlisted',
        ),
      );

      useCase = OrchestrateScamAnalysisUseCase(
        scamAnalysisRepository: scamRepo,
        piiRedactionRepository: pii,
        virusTotalRepository: vt,
        abuseIpdbRepository: MockAbuseIpdbRepository(),
        urlScanRepository: urlScan,
        emlParseRepository: MockEmlParseRepository(),
        buildAugmentedPromptUseCase: const BuildAugmentedPromptUseCase(),
        connectivityRepository: connectivity,
        localAnalysisRepository: MockLocalAnalysisRepository(),
        modelRepository: MockModelRepository(),
      );
    });

    for (final sample in ExampleMessages.samples) {
      test(
        'online pipeline forwards "${sample.title}" '
        'and returns ${sample.expectedRisk.label}',
        () async {
          when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer((inv) async {
            final prompt = inv.positionalArguments.first as String;
            expect(prompt, contains(sample.body));
            return ScamAnalysis(
              riskLevel: sample.expectedRisk,
              confidence: 88,
              explanation: 'Test stub for ${sample.title}',
            );
          });

          final outcome = await useCase(
            SoarAnalysisInput(
              rawContent: sample.body,
              kind: SoarInputKind.plainText,
            ),
          );

          expect(outcome, isA<AnalysisSuccess>());
          final success = outcome as AnalysisSuccess;
          expect(success.result.riskLevel, sample.expectedRisk);
          verify(scamRepo.analyzeAugmentedPrompt(any)).called(1);
        },
      );
    }

    test('augmented prompt embeds suspicious copy without OSINT when incognito',
        () async {
      final sample = ExampleMessages.withRisk(RiskLevel.suspicious).first;
      when(scamRepo.analyzeAugmentedPrompt(any)).thenAnswer((inv) async {
        final prompt = inv.positionalArguments.first as String;
        expect(prompt, contains(sample.body));
        expect(prompt, contains('OSINT lookups were skipped'));
        return const ScamAnalysis(
          riskLevel: RiskLevel.suspicious,
          confidence: 70,
          explanation: 'Incognito path',
        );
      });

      await useCase(
        SoarAnalysisInput(
          rawContent: sample.body,
          kind: SoarInputKind.plainText,
          incognitoEnabled: true,
        ),
      );
    });
  });
}
