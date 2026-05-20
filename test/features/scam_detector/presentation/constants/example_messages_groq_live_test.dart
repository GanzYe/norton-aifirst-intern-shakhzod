import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_message_detector/core/env/env.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';

/// Live Groq checks — requires `.env` with `GROQ_API_KEY`.
///
/// Run: `flutter test test/features/scam_detector/presentation/constants/example_messages_groq_live_test.dart`
void main() {
  late GroqRemoteDataSource groq;

  setUpAll(() {
    if (Env.groqApiKey.isEmpty) return;
    groq = GroqRemoteDataSource(
      dio: Dio(
        BaseOptions(
          baseUrl: 'https://api.groq.com',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
      apiKey: Env.groqApiKey,
    );
  });

  group('ExampleMessages Groq live classification', () {
    for (final sample in ExampleMessages.samples) {
      test(
        '${sample.title} is classified ${sample.expectedRisk.label} by Groq',
        () async {
          if (Env.groqApiKey.isEmpty) {
            markTestSkipped('GROQ_API_KEY missing in .env');
          }

          final prompt = ExampleMessages.masterPromptFor(sample);
          final dto = await groq.analyzeAugmentedContent(prompt);
          final actual = RiskLevel.fromString(dto.riskLevel);

          expect(
            actual,
            sample.expectedRisk,
            reason:
                'Groq returned ${dto.riskLevel} '
                '(confidence ${dto.confidence}). '
                'Explanation: ${dto.explanation}',
          );
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    }
  });
}
