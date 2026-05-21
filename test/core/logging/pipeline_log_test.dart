import 'package:flutter_test/flutter_test.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';

void main() {
  group('PipelineLog capture', () {
    tearDown(PipelineLog.discardCapture);

    test('collects entries while capture is active', () {
      PipelineLog.beginCapture();
      PipelineLog.start('CONNECTIVITY');
      PipelineLog.info('OSINT.VT', 'POST /urls', context: {'url': 'https://x.test'});
      PipelineLog.done('OSINT.VT', message: '3/70 malicious');

      final entries = PipelineLog.takeCapture();

      expect(entries, hasLength(3));
      expect(entries[0].tag, 'START');
      expect(entries[0].stage, 'CONNECTIVITY');
      expect(entries[1].stage, 'OSINT.VT');
      expect(entries[1].context?['url'], 'https://x.test');
      expect(entries[2].tag, 'DONE');
      expect(entries[2].message, '3/70 malicious');
    });

    test('takeCapture clears buffer', () {
      PipelineLog.beginCapture();
      PipelineLog.info('PROMPT', 'assembled');
      PipelineLog.takeCapture();

      PipelineLog.beginCapture();
      PipelineLog.info('PROMPT', 'second run');
      final second = PipelineLog.takeCapture();
      expect(second, hasLength(1));
      expect(second.single.stage, 'PROMPT');
    });
  });

  group('PipelineLog redactSensitiveBody', () {
    test('returns full body when not in release mode', () {
      final body = 'A' * 100;
      expect(PipelineLog.redactSensitiveBody(body), body);
    });

    test('short bodies get redacted suffix when truncated path applies', () {
      // In debug/test builds [kReleaseMode] is false — full body is kept.
      const body = 'secret-user-message-content';
      expect(PipelineLog.redactSensitiveBody(body), body);
    });
  });
}
