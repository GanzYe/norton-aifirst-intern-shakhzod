import 'dart:async';

import 'package:flutter_llama/flutter_llama.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_llama_inference.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockFlutterLlama llama;
  late LocalLlamaInference inference;

  setUp(() {
    llama = MockFlutterLlama();
    inference = LocalLlamaInference(llama);
  });

  test('settles in-flight generation on TimeoutException', () async {
    final completer = Completer<LlamaResponse>();
    when(llama.generate(any)).thenAnswer((_) => completer.future);
    when(llama.stopGeneration()).thenAnswer((_) async {});

    await expectLater(
      inference.generate(
        const GenerationParams(prompt: 'hi'),
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );

    verify(llama.stopGeneration()).called(1);
  });

  test('settles in-flight generation on non-timeout errors', () async {
    when(llama.generate(any)).thenThrow(StateError('native failure'));
    when(llama.stopGeneration()).thenAnswer((_) async {});

    await expectLater(
      inference.generate(const GenerationParams(prompt: 'hi')),
      throwsA(isA<StateError>()),
    );

    verify(llama.stopGeneration()).called(1);
  });

  test('stopGeneration is capped so a stuck native call cannot hang forever',
      () async {
    final completer = Completer<LlamaResponse>();
    when(llama.generate(any)).thenAnswer((_) => completer.future);
    when(llama.stopGeneration()).thenAnswer(
      (_) => Completer<void>().future,
    );

    await expectLater(
      inference.generate(
        const GenerationParams(prompt: 'hi'),
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );

    verify(llama.stopGeneration()).called(1);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
