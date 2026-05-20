import 'package:flutter_llama/flutter_llama.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_llama_inference.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/risk_level.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockFlutterLlama llama;
  late LocalLlamaInference llamaInference;
  late MockModelDownloadService modelDownload;
  late MockLlamaNativeProbe probe;
  late LocalScamAnalysisService service;

  const modelPath = '/data/user/0/app/files/qwen2.5-1.5b-instruct-q4_k_m.gguf';

  void wireHealthyEnv() {
    when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
    when(modelDownload.getModelPath()).thenAnswer((_) async => modelPath);
    when(probe.isAvailable()).thenAnswer((_) async => true);
    when(llama.loadModel(any)).thenAnswer((_) async => true);
  }

  setUp(() {
    llama = MockFlutterLlama();
    llamaInference = LocalLlamaInference(llama);
    modelDownload = MockModelDownloadService();
    probe = MockLlamaNativeProbe();
    service = LocalScamAnalysisService(
      llamaInference: llamaInference,
      modelDownloadService: modelDownload,
      nativeProbe: probe,
    );
  });

  group('LocalScamAnalysisService.parseModelResponseForTest', () {
    test('parses a clean JSON object', () {
      const raw = '{"risk_level":"DANGEROUS","confidence":92,'
          '"explanation":"Phishing link plus urgency."}';
      final result = service.parseModelResponseForTest(raw);
      expect(result.riskLevel, RiskLevel.dangerous);
      expect(result.confidence, 92);
      expect(result.explanation, contains('Phishing'));
    });

    test('strips ChatML artifacts before parsing', () {
      final raw = [
        'assistant\n',
        '{"risk_level":"SAFE","confidence":80,',
        '"explanation":"Routine notification."}',
        kChatMlImEnd,
      ].join();
      final result = service.parseModelResponseForTest(raw);
      expect(result.riskLevel, RiskLevel.safe);
      expect(result.confidence, 80);
    });

    test('parses JSON wrapped in markdown fences', () {
      const raw = '''
```json
{"risk_level":"SUSPICIOUS","confidence":60,"explanation":"Urgent wording warrants caution."}
```
''';
      final result = service.parseModelResponseForTest(raw);
      expect(result.riskLevel, RiskLevel.suspicious);
      expect(result.confidence, 60);
    });

    test(
      'falls back to natural-language LABEL: explanation (regression)',
      () {
        const raw = 'SUSPICIOUS: The message appears to be a phishing '
            'attempt. The sender mimics a bank.';
        final result = service.parseModelResponseForTest(raw);
        expect(result.riskLevel, RiskLevel.suspicious);
        expect(result.explanation, contains('phishing'));
        expect(result.confidence, inInclusiveRange(0, 100));
      },
    );

    test('recovers DANGEROUS verdict from prose without colon', () {
      const raw =
          'This is clearly DANGEROUS — phishing for banking credentials.';
      final result = service.parseModelResponseForTest(raw);
      expect(result.riskLevel, RiskLevel.dangerous);
    });

    test('throws when response is unparseable garbage', () {
      const raw = 'lorem ipsum dolor sit amet';
      expect(
        () => service.parseModelResponseForTest(raw),
        throwsA(isA<LocalScamAnalysisException>()),
      );
    });

    test('clamps absurd confidence values to 0..100', () {
      const raw =
          '{"risk_level":"DANGEROUS","confidence":9999,"explanation":"x"}';
      final result = service.parseModelResponseForTest(raw);
      expect(result.confidence, 100);
    });
  });

  group('LocalScamAnalysisService.analyze — preconditions', () {
    test('throws when model is not downloaded', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => false);

      expect(
        () => service.analyze('hello'),
        throwsA(
          isA<LocalScamAnalysisException>().having(
            (e) => e.message,
            'message',
            contains('not downloaded'),
          ),
        ),
      );
      verifyNever(llama.loadModel(any));
    });

    test('throws when native probe is unavailable', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(probe.isAvailable()).thenAnswer((_) async => false);

      expect(
        () => service.analyze('hello'),
        throwsA(
          isA<LocalScamAnalysisException>().having(
            (e) => e.message,
            'message',
            contains('not available'),
          ),
        ),
      );
      verifyNever(llama.loadModel(any));
    });
  });

  group('LocalScamAnalysisService.analyze — happy path', () {
    test('returns ScamAnalysis when the model emits valid JSON', () async {
      wireHealthyEnv();
      when(llama.generate(any)).thenAnswer(
        (_) async => const LlamaResponse(
          text: '{"risk_level":"DANGEROUS","confidence":91,'
              '"explanation":"Suspicious .tk login link."}',
          tokensGenerated: 32,
          generationTimeMs: 1200,
        ),
      );

      final result = await service.analyze(
        'Your account has been suspended. Click http://x.example.tk now.',
      );

      expect(result.riskLevel, RiskLevel.dangerous);
      expect(result.confidence, 91);
      expect(result.resolvedLocally, isTrue);
      verify(llama.loadModel(any)).called(1);
      verify(llama.generate(any)).called(1);
    });

    test('recovers from non-JSON output via natural-language parser', () async {
      wireHealthyEnv();
      when(llama.generate(any)).thenAnswer(
        (_) async => const LlamaResponse(
          text: 'SUSPICIOUS: The message appears to be a phishing attempt.',
          tokensGenerated: 14,
          generationTimeMs: 800,
        ),
      );

      final result = await service.analyze('long suspicious message');

      expect(result.riskLevel, RiskLevel.suspicious);
      expect(result.resolvedLocally, isTrue);
      expect(result.explanation, isNotEmpty);
    });

    test(
      'reloads the model and unloads after every analyze() so the KV cache '
      'stays clean (regression for ggml_abort SIGABRT on the second call)',
      () async {
        // flutter_llama 1.1.2's native bridge never calls
        // `llama_kv_cache_clear()` between independent generate() calls, so
        // re-using a model load across calls trips `ggml_abort` inside
        // `llama_context::decode`. Each analyze() must therefore do a full
        // load/generate/unload cycle.
        wireHealthyEnv();
        when(llama.generate(any)).thenAnswer(
          (_) async => const LlamaResponse(
            text: '{"risk_level":"SAFE","confidence":70,"explanation":"x"}',
          ),
        );

        await service.analyze('one');
        await service.analyze('two');

        verify(llama.loadModel(any)).called(2);
        verify(llama.generate(any)).called(2);
        verify(llama.unloadModel()).called(2);
      },
    );

    test('configures the model with a 4096-token context window', () async {
      wireHealthyEnv();
      when(llama.generate(any)).thenAnswer(
        (_) async => const LlamaResponse(
          text: '{"risk_level":"SAFE","confidence":50,"explanation":"x"}',
        ),
      );

      await service.analyze('hello');

      final config =
          verify(llama.loadModel(captureAny)).captured.single as LlamaConfig;
      expect(config.contextSize, 4096);
      expect(config.useGpu, isFalse);
    });

    test(
      'sizes batchSize >= contextSize so single-batch prefill cannot overflow '
      'n_batch (regression for ggml_abort SIGABRT on scam prompts >256 tokens)',
      () async {
        // flutter_llama 1.1.2's native bridge submits the whole prompt as
        // ONE `llama_batch` (see flutter_llama_bridge.cpp:154). When the
        // batch is larger than n_batch, llama.cpp hits a GGML_ASSERT
        // inside `llama_context::decode` and the process aborts. The
        // ChatML-wrapped scam prompt (system + few-shot + user) is
        // always larger than 256 tokens, so batchSize=256 reliably
        // crashed the app — keep this assertion to prevent regression.
        wireHealthyEnv();
        when(llama.generate(any)).thenAnswer(
          (_) async => const LlamaResponse(
            text: '{"risk_level":"SAFE","confidence":50,"explanation":"x"}',
          ),
        );

        await service.analyze('hello');

        final config =
            verify(llama.loadModel(captureAny)).captured.single as LlamaConfig;
        expect(config.batchSize, greaterThanOrEqualTo(config.contextSize));
      },
    );
  });

  group('LocalScamAnalysisService.analyze — failure paths', () {
    test('throws when loadModel returns false', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(modelDownload.getModelPath()).thenAnswer((_) async => modelPath);
      when(probe.isAvailable()).thenAnswer((_) async => true);
      when(llama.loadModel(any)).thenAnswer((_) async => false);

      expect(
        () => service.analyze('hello'),
        throwsA(isA<LocalScamAnalysisException>()),
      );
    });

    test('throws when generate returns empty text', () async {
      wireHealthyEnv();
      when(
        llama.generate(any),
      ).thenAnswer((_) async => const LlamaResponse(text: '   '));

      expect(
        () => service.analyze('hello'),
        throwsA(
          isA<LocalScamAnalysisException>().having(
            (e) => e.message,
            'message',
            contains('Empty'),
          ),
        ),
      );
    });

    test(
      'wraps unexpected exceptions into LocalScamAnalysisException',
      () async {
        wireHealthyEnv();
        when(llama.generate(any)).thenThrow(StateError('native crash'));

        expect(
          () => service.analyze('hello'),
          throwsA(isA<LocalScamAnalysisException>()),
        );
      },
    );
  });

  group('LocalScamAnalysisService.isUsable', () {
    test(
      'returns true only when model is on disk AND native probe healthy',
      () async {
        when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
        when(probe.isAvailable()).thenAnswer((_) async => true);
        expect(await service.isUsable(), isTrue);
      },
    );

    test('returns false if model is missing', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => false);
      expect(await service.isUsable(), isFalse);
    });

    test('returns false if native probe is unhealthy', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(probe.isAvailable()).thenAnswer((_) async => false);
      expect(await service.isUsable(), isFalse);
    });
  });
}
