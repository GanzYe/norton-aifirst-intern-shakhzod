import 'package:flutter_llama/flutter_llama.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_pii_redaction_service.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockFlutterLlama llama;
  late MockModelDownloadService modelDownload;
  late MockLlamaNativeProbe probe;
  late LocalPiiRedactionService service;

  const modelPath = '/data/user/0/app/files/qwen2.5-1.5b-instruct-q4_k_m.gguf';

  void wireHealthyEnv() {
    when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
    when(modelDownload.getModelPath()).thenAnswer((_) async => modelPath);
    when(probe.isAvailable()).thenAnswer((_) async => true);
    when(llama.loadModel(any)).thenAnswer((_) async => true);
    when(llama.unloadModel()).thenAnswer((_) async {});
  }

  setUp(() {
    llama = MockFlutterLlama();
    modelDownload = MockModelDownloadService();
    probe = MockLlamaNativeProbe();
    service = LocalPiiRedactionService(
      llama: llama,
      modelDownloadService: modelDownload,
      nativeProbe: probe,
    );
  });

  group('LocalPiiRedactionService — regex', () {
    test('redacts emails', () {
      final out = service.regexScrubForTest(
        'Reply to john.doe+spam@example.co.uk now.',
      );
      expect(out, contains('[REDACTED_EMAIL]'));
    });

    test('redacts greeting names and API keys', () {
      const input =
          "Hello Shakhzod, it's a pleasure to meet you. "
          'Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.';

      final out = service.regexScrubForTest(input);
      expect(out, contains('Hello [REDACTED_NAME]'));
      expect(out, isNot(contains('Shakhzod')));
      expect(out, contains('[REDACTED_SECRET]'));
      expect(out, isNot(contains('AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM')));
      expect(service.stillContainsPiiForTest(out), isFalse);
    });

    test('preserves IRS scam wording and redacts agent name', () {
      const irsScam =
          'Final Notice from IRS: A warrant has been issued for your arrest '
          r'due to unpaid taxes. Pay $4,250 today via gift cards to avoid '
          'legal action. Contact agent Smith immediately.';

      final out = service.regexScrubForTest(irsScam);
      expect(out, contains('Final Notice from IRS'));
      expect(out, contains('Contact agent [REDACTED_NAME]'));
      expect(out, isNot(contains('Smith')));
    });
  });

  group('LocalPiiRedactionService.isAcceptableLlmScrubForTest', () {
    const irsScam =
        'Final Notice from IRS: A warrant has been issued for your arrest '
        r'due to unpaid taxes. Pay $4,250 today via gift cards to avoid '
        'legal action. Contact agent Smith immediately.';

    test('rejects output that starts with [REDACTED]', () {
      expect(
        service.isAcceptableLlmScrubForTest(
          irsScam,
          '[REDACTED] has been issued a warrant for your arrest due to '
          r'unpaid taxes. Pay $4,250 today via gift cards to avoid legal '
          'action. Contact agent Smith immediately.',
        ),
        isFalse,
      );
    });

    test('rejects LLM output that still exposes secrets', () {
      const input =
          'Hello Shakhzod, Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.';
      expect(service.isAcceptableLlmScrubForTest(input, input), isFalse);
    });

    test('accepts inline redaction that keeps scam keywords', () {
      expect(
        service.isAcceptableLlmScrubForTest(
          irsScam,
          'Final Notice from IRS: A warrant has been issued for your arrest '
          r'due to unpaid taxes. Pay $4,250 today via gift cards to avoid '
          'legal action. Contact [REDACTED] immediately.',
        ),
        isTrue,
      );
    });
  });

  group('LocalPiiRedactionService — LLM + regex hybrid', () {
    test('uses regex baseline when model is missing', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => false);

      const input = 'Contact agent Smith at a@b.com';
      final out = await service.scrubPii(input);

      expect(out, contains('[REDACTED_EMAIL]'));
      expect(out, contains('[REDACTED_NAME]'));
      verifyNever(llama.generate(any));
    });

    test('falls back to regex when LLM returns secrets unchanged', () async {
      wireHealthyEnv();
      const input =
          "Hello Shakhzod, it's a pleasure. "
          'Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.';
      when(
        llama.generate(any),
      ).thenAnswer((_) async => const LlamaResponse(text: input));

      final out = await service.scrubPii(input);

      expect(out, contains('Hello [REDACTED_NAME]'));
      expect(out, contains('[REDACTED_SECRET]'));
      expect(out, isNot(contains('Shakhzod')));
      expect(out, isNot(contains('AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM')));
    });

    test(
      'falls back to regex when LLM replaces the opening with [REDACTED]',
      () async {
        wireHealthyEnv();
        when(llama.generate(any)).thenAnswer(
          (_) async => const LlamaResponse(
            text:
                '[REDACTED] has been issued a warrant for your arrest due '
                r'to unpaid taxes. Pay $4,250 today via gift cards to avoid '
                'legal action. Contact agent Smith immediately.',
          ),
        );

        const irsScam =
            'Final Notice from IRS: A warrant has been issued for your arrest '
            r'due to unpaid taxes. Pay $4,250 today via gift cards to avoid '
            'legal action. Contact agent Smith immediately.';

        final out = await service.scrubPii(irsScam);

        expect(out, contains('Final Notice from IRS'));
        expect(out, contains('[REDACTED_NAME]'));
        expect(out, isNot(contains('Smith')));
        verify(llama.unloadModel()).called(1);
      },
    );

    test('applies regex on top of acceptable LLM output', () async {
      wireHealthyEnv();
      when(llama.generate(any)).thenAnswer(
        (_) async => const LlamaResponse(
          text: 'Final Notice from IRS: Contact agent Smith about taxes.',
        ),
      );

      final out = await service.scrubPii(
        'Final Notice from IRS: Contact agent Smith about taxes.',
      );

      expect(out, contains('Final Notice from IRS'));
      expect(out, contains('[REDACTED_NAME]'));
      expect(out, isNot(contains('Smith')));
    });

    test('wraps user text in ChatML and unloads after each call', () async {
      wireHealthyEnv();
      when(llama.generate(any)).thenAnswer(
        (_) async => const LlamaResponse(
          text: 'Final Notice from IRS: Contact [REDACTED] about taxes.',
        ),
      );

      await service.scrubPii(
        'Final Notice from IRS: Contact agent Smith about taxes.',
      );

      final captured =
          verify(llama.generate(captureAny)).captured.single
              as GenerationParams;
      expect(captured.prompt, contains('<|im_start|>user'));
      expect(
        captured.prompt,
        contains('Final Notice from IRS: Contact agent Smith about taxes'),
      );
      expect(captured.stopSequences, contains('<|im_end|>'));
      verify(llama.unloadModel()).called(1);
    });
  });

  group('LocalPiiRedactionService.stripChatMlArtifactsForTest', () {
    test('removes ChatML markers', () {
      expect(
        service.stripChatMlArtifactsForTest('assistant\nHello world<|im_end|>'),
        'Hello world',
      );
    });
  });
}
