import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/dtos/scam_analysis_dto.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/scam_analysis_repository_impl.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockGroqRemoteDataSource groq;
  late MockGeminiRemoteDataSource gemini;
  late ScamAnalysisRepositoryImpl repository;

  const message = 'Wire transfer required by EOD to keep your account active.';

  ScamAnalysisDto dto(String risk, int confidence) => ScamAnalysisDto(
        riskLevel: risk,
        confidence: confidence,
        explanation: 'verdict-from-fake',
      );

  setUp(() {
    groq = MockGroqRemoteDataSource();
    gemini = MockGeminiRemoteDataSource();
    repository = ScamAnalysisRepositoryImpl(
      groqRemoteDataSource: groq,
      geminiRemoteDataSource: gemini,
    );
  });

  group('ScamAnalysisRepositoryImpl — cloud cascade', () {
    test('uses Groq when configured and Groq succeeds', () async {
      when(groq.isConfigured).thenReturn(true);
      when(groq.analyzeMessage(message))
          .thenAnswer((_) async => dto('SAFE', 90));

      final result = await repository.analyzeMessage(message);

      expect(result.riskLevel.label, 'SAFE');
      expect(result.confidence, 90);
      verifyNever(gemini.analyzeMessage(any));
    });

    test('falls through to Gemini when Groq rate-limits (429/402)',
        () async {
      when(groq.isConfigured).thenReturn(true);
      when(groq.analyzeMessage(message)).thenThrow(
        const GroqDataSourceException(
          'rate limited',
          rateLimited: true,
        ),
      );
      when(gemini.analyzeMessage(message))
          .thenAnswer((_) async => dto('DANGEROUS', 95));

      final result = await repository.analyzeMessage(message);

      expect(result.riskLevel.label, 'DANGEROUS');
      verify(gemini.analyzeMessage(message)).called(1);
    });

    test('falls through to Gemini on any GroqDataSourceException', () async {
      when(groq.isConfigured).thenReturn(true);
      when(groq.analyzeMessage(message)).thenThrow(
        const GroqDataSourceException(
          'parse error',
          rateLimited: false,
        ),
      );
      when(gemini.analyzeMessage(message))
          .thenAnswer((_) async => dto('SUSPICIOUS', 60));

      final result = await repository.analyzeMessage(message);
      expect(result.riskLevel.label, 'SUSPICIOUS');
      verify(gemini.analyzeMessage(message)).called(1);
    });

    test('skips Groq entirely when not configured (no API key)', () async {
      when(groq.isConfigured).thenReturn(false);
      when(gemini.analyzeMessage(message))
          .thenAnswer((_) async => dto('SAFE', 80));

      final result = await repository.analyzeMessage(message);

      expect(result.riskLevel.label, 'SAFE');
      verifyNever(groq.analyzeMessage(any));
      verify(gemini.analyzeMessage(message)).called(1);
    });

    test('propagates GeminiDataSourceException when both fail', () async {
      when(groq.isConfigured).thenReturn(true);
      when(groq.analyzeMessage(message)).thenThrow(
        const GroqDataSourceException('groq down', rateLimited: true),
      );
      when(gemini.analyzeMessage(message)).thenThrow(
        const GeminiDataSourceException('gemini down'),
      );

      expect(
        () => repository.analyzeMessage(message),
        throwsA(isA<GeminiDataSourceException>()),
      );
    });

    test('analyzeAugmentedPrompt uses the augmented-content endpoints',
        () async {
      const masterPrompt = '## User content\n<scrubbed>\n## Threat intel\n- VT: 5/76';
      when(groq.isConfigured).thenReturn(true);
      when(groq.analyzeAugmentedContent(masterPrompt))
          .thenAnswer((_) async => dto('DANGEROUS', 88));

      final result = await repository.analyzeAugmentedPrompt(masterPrompt);

      expect(result.riskLevel.label, 'DANGEROUS');
      verify(groq.analyzeAugmentedContent(masterPrompt)).called(1);
      verifyNever(gemini.analyzeAugmentedContent(any));
    });
  });
}
