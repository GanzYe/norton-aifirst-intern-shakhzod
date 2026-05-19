import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_pii_redaction_service.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockFlutterLlama llama;
  late MockModelDownloadService modelDownload;
  late MockLlamaNativeProbe probe;
  late LocalPiiRedactionService service;

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

  group('LocalPiiRedactionService — regex fallback (no on-device model)', () {
    setUp(() {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => false);
    });

    test('redacts emails', () async {
      final out = await service.scrubPii('Reply to john.doe+spam@example.co.uk now.');
      expect(out, contains('[REDACTED_EMAIL]'));
      expect(out, isNot(contains('john.doe+spam@example.co.uk')));
    });

    test('redacts US phone numbers', () async {
      final out = await service.scrubPii('Call +1 (415) 555-2671 immediately.');
      expect(out, contains('[REDACTED_PHONE]'));
    });

    test('redacts US SSN-like patterns', () async {
      final out = await service.scrubPii('SSN on file: 123-45-6789.');
      expect(out, contains('[REDACTED_SSN]'));
    });

    test('redacts credit-card-like patterns', () async {
      final out = await service.scrubPii(
        'Card 4242-4242-4242-4242 expires soon.',
      );
      expect(out, contains('[REDACTED_CARD]'));
    });

    test('leaves clean input untouched', () async {
      final out = await service.scrubPii('Nothing sensitive in here.');
      expect(out, 'Nothing sensitive in here.');
    });

    test('falls back to regex when native probe is unavailable', () async {
      when(modelDownload.isModelDownloaded()).thenAnswer((_) async => true);
      when(probe.isAvailable()).thenAnswer((_) async => false);

      final out = await service.scrubPii('email me at a@b.com');
      expect(out, contains('[REDACTED_EMAIL]'));
      verifyNever(llama.loadModel(any));
      verifyNever(llama.generate(any));
    });
  });
}
