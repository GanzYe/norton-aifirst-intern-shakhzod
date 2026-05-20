import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_llama/flutter_llama.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/llama_native_probe.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/pii_regex_scrubber.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';

const _imStart = '<|im_start|>';
const _imEnd = '<|im_end|>';

const _piiSystemPrompt = '''
You are an on-device PII redaction tool. You receive ONE user message and must return that same message with every piece of private data replaced by a token. Output ONLY the redacted message — no explanations, no JSON, no markdown.

## WHAT YOU MUST REMOVE (replace the sensitive span only)

1. PERSON NAMES → [REDACTED_NAME]
   Any human identifier: first name, last name, full name, nickname.
   Examples: Shakhzod, John, Jane Doe, agent Smith, Officer Miller.
   Also after: Hello, Hi, Dear, I am, I'm, it is, it's, my name is,
   this is, call me, contact, agent, Mr/Mrs/Dr.
   CRITICAL: If a name appears MORE THAN ONCE, redact EVERY occurrence.
   WRONG: "Hello [REDACTED_NAME], it is Shakhzod."
   RIGHT: "Hello [REDACTED_NAME], it is [REDACTED_NAME]."

2. EMAIL ADDRESSES → [REDACTED_EMAIL]
   Anything like user@domain.com.

3. PHONE / SMS / FAX NUMBERS → [REDACTED_PHONE]
   Mobile, landline, international formats.

4. SECRETS & CREDENTIALS → [REDACTED_SECRET]
   API keys, passwords, access tokens, auth tokens, bearer tokens, PINs,
   OTP codes, private keys, long random alphanumeric secrets (often 16+ chars).
   Replace the secret VALUE, keep labels like "API key is" if present.

5. GOVERNMENT / FINANCIAL IDs → [REDACTED_SSN] or [REDACTED_CARD]
   SSN (123-45-6789), payment card numbers.

6. STREET ADDRESSES → [REDACTED_ADDRESS]
   Number + street + city when it identifies a residence.

7. BANK / ACCOUNT NUMBERS → [REDACTED_ACCOUNT]
   Account, routing, IBAN-style numbers.

## WHAT YOU MUST NOT REMOVE

• Organization or agency names: IRS, FBI, Amazon, Microsoft, bank brand names.
• Scam story text: threats, urgency, dollar amounts, gift cards, warrants.
• Generic URLs/domains unless they embed a personal email or login credential.
• Words that are not PII (even if the message is about a scam).

## OUTPUT RULES

1. Keep the same sentences, order, and punctuation — only swap PII spans.
2. Never replace the whole message with a single token.
3. Never re-introduce a real name after you used [REDACTED_NAME].
4. Never leave a visible name, email, phone, or secret string.
5. When unsure whether something is PII, redact it.
6. Do not add new words or commentary.
''';

const _fewShotUserA =
    "Hello Shakhzod, it's a pleasure to meet you. "
    'Your API key is AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.';
const _fewShotAssistantA =
    "Hello [REDACTED_NAME], it's a pleasure to meet you. "
    'Your API key is [REDACTED_SECRET].';

const _fewShotUserB =
    'Final Notice from IRS: Pay \$4,250 via gift cards. '
    'Contact agent Smith at john.doe@irs-scam.example or +1 (202) 555-0199.';
const _fewShotAssistantB =
    'Final Notice from IRS: Pay \$4,250 via gift cards. '
    'Contact agent [REDACTED_NAME] at [REDACTED_EMAIL] or [REDACTED_PHONE].';

const _fewShotUserC =
    'Hello Shakhzod, it is Shakhzod. There is an API key '
    'AIWHHQOSOWBWHJ18HWJAJ78BWO8JWOM.';
const _fewShotAssistantC =
    'Hello [REDACTED_NAME], it is [REDACTED_NAME]. '
    'There is an API key [REDACTED_SECRET].';

const _maxInputChars = 1800;
const _maxOutputTokens = 768;

/// On-device PII scrubbing via Qwen2.5-1.5B with regex as a safety net.
class LocalPiiRedactionService implements PiiRedactionRepository {
  LocalPiiRedactionService({
    required FlutterLlama llama,
    required ModelDownloadService modelDownloadService,
    required LlamaNativeProbe nativeProbe,
  })  : _llama = llama,
        _modelDownload = modelDownloadService,
        _nativeProbe = nativeProbe;

  static const _loadTimeout = Duration(seconds: 45);
  static const _generateTimeout = Duration(minutes: 1);

  final FlutterLlama _llama;
  final ModelDownloadService _modelDownload;
  final LlamaNativeProbe _nativeProbe;

  static const _stage = 'PII';

  @override
  Future<String> scrubPii(String input) async {
    PipelineLog.start(_stage, context: {'inputChars': input.length});
    PipelineLog.piiInput(input);

    final regexBaseline = PiiRegexScrubber.scrub(input);

    if (!await _modelDownload.isModelDownloaded()) {
      PipelineLog.info(_stage, 'model not on disk; regex only');
      return _finish(regexBaseline, via: 'regex');
    }
    if (!await _nativeProbe.isAvailable()) {
      PipelineLog.info(_stage, 'native engine unavailable; regex only');
      return _finish(regexBaseline, via: 'regex');
    }

    var loaded = false;
    try {
      final modelPath = await _modelDownload.getModelPath();
      await _loadModelFresh(modelPath);
      loaded = true;

      // Send the original message to the LLM (pre-scrubbing caused broken
      // fragments like "Hello [REDACTED_NAME] is Shakhzod"). Regex runs on
      // the model reply and again on the original if the reply still leaks.
      final truncated = _truncateForContext(input);
      final prompt = _buildChatMlPrompt(truncated);
      PipelineLog.info(
        _stage,
        'invoking on-device LLM for PII scrub',
        context: {'promptChars': prompt.length},
      );
      PipelineLog.piiModelPrompt(truncated);

      final params = GenerationParams(
        prompt: prompt,
        temperature: 0.1,
        topP: 0.9,
        topK: 40,
        maxTokens: _maxOutputTokens,
        repeatPenalty: 1.1,
        stopSequences: const [_imEnd, '<|endoftext|>'],
      );

      final response = await _llama.generate(params).timeout(_generateTimeout);
      final raw = response.text;
      PipelineLog.modelResponse(source: 'PII_LLM (raw)', response: raw);

      final llmBody = _stripChatMlArtifacts(raw);
      if (!_isAcceptableLlmScrub(input, llmBody)) {
        PipelineLog.warn(
          _stage,
          'LLM scrub rejected; using regex baseline',
          context: {
            'inputChars': input.length,
            'llmChars': llmBody.length,
          },
        );
        return _finish(regexBaseline, via: 'regex');
      }

      var merged = PiiRegexScrubber.scrub(llmBody);
      if (_stillContainsPii(merged)) {
        PipelineLog.warn(
          _stage,
          'PII still detectable after LLM+regex; scrubbing original input',
        );
        merged = PiiRegexScrubber.scrub(input);
      }
      return _finish(merged, via: 'llm+regex');
    } on Object catch (e, stack) {
      developer.log(
        'Local LLM redaction failed; using regex baseline.',
        name: 'LocalPiiRedactionService',
        error: e,
        stackTrace: stack,
      );
      PipelineLog.warn(_stage, 'LLM scrub failed; using regex', error: e);
      return _finish(regexBaseline, via: 'regex');
    } finally {
      if (loaded) {
        await _safeUnload();
      }
    }
  }

  Future<void> _loadModelFresh(String modelPath) async {
    final config = LlamaConfig(
      modelPath: modelPath,
      nThreads: 4,
      nGpuLayers: 0,
      contextSize: 4096,
      batchSize: 4096,
      useGpu: false,
      verbose: false,
    );

    final loaded = await _llama.loadModel(config).timeout(_loadTimeout);
    if (!loaded) {
      throw const PiiRedactionException('Failed to load local Llama model.');
    }
  }

  Future<void> _safeUnload() async {
    try {
      await _llama.unloadModel();
    } on Object catch (e, stack) {
      developer.log(
        'unloadModel() failed after PII scrub; ignoring',
        name: 'LocalPiiRedactionService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  String _buildChatMlPrompt(String message) {
    final buffer = StringBuffer()
      ..writeln('${_imStart}system')
      ..writeln(_piiSystemPrompt)
      ..writeln(_imEnd)
      ..writeln('${_imStart}user')
      ..writeln(_fewShotUserA)
      ..writeln(_imEnd)
      ..writeln('${_imStart}assistant')
      ..writeln(_fewShotAssistantA)
      ..writeln(_imEnd)
      ..writeln('${_imStart}user')
      ..writeln(_fewShotUserB)
      ..writeln(_imEnd)
      ..writeln('${_imStart}assistant')
      ..writeln(_fewShotAssistantB)
      ..writeln(_imEnd)
      ..writeln('${_imStart}user')
      ..writeln(_fewShotUserC)
      ..writeln(_imEnd)
      ..writeln('${_imStart}assistant')
      ..writeln(_fewShotAssistantC)
      ..writeln(_imEnd)
      ..writeln('${_imStart}user')
      ..writeln(message)
      ..writeln(_imEnd)
      ..write('${_imStart}assistant\n');
    return buffer.toString();
  }

  String _truncateForContext(String message) {
    final collapsed = message.replaceAll(RegExp(r'[\t\f\v]+'), ' ').trim();
    if (collapsed.length <= _maxInputChars) return collapsed;
    return '${collapsed.substring(0, _maxInputChars)}…';
  }

  @visibleForTesting
  String regexScrubForTest(String input) => PiiRegexScrubber.scrub(input);

  @visibleForTesting
  String stripChatMlArtifactsForTest(String raw) => _stripChatMlArtifacts(raw);

  @visibleForTesting
  bool isAcceptableLlmScrubForTest(String input, String output) =>
      _isAcceptableLlmScrub(input, output);

  @visibleForTesting
  bool stillContainsPiiForTest(String text) => _stillContainsPii(text);

  bool _stillContainsPii(String text) =>
      PiiRegexScrubber.containsDetectablePii(text);

  bool _isAcceptableLlmScrub(String input, String output) {
    final inTrim = input.trim();
    final out = output.trim();
    if (out.isEmpty) return false;
    if (_stillContainsPii(out)) return false;
    if (RegExp(r'^\[REDACTED\]\s*$').hasMatch(out)) return false;
    if (RegExp(r'^(\[REDACTED_[A-Z]+\]\s*)+$').hasMatch(out)) return false;

    // Reject when the model replaces the opening with a lone [REDACTED].
    if (out.startsWith('[REDACTED]') && !inTrim.startsWith('[REDACTED]')) {
      return false;
    }

    final inLen = inTrim.length;
    final outLen = out.length;
    if (inLen >= 40 && outLen < (inLen * 0.55).round()) return false;

    return _preservesMessageWording(inTrim, out);
  }

  /// Ensures major non-PII words from the input survive in the model output.
  bool _preservesMessageWording(String input, String output) {
    final keywords = input
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 4)
        .toSet();
    if (keywords.isEmpty) return true;

    final outLower = output.toLowerCase();
    var hits = 0;
    for (final word in keywords) {
      if (outLower.contains(word)) hits++;
    }
    return hits >= (keywords.length * 0.55).ceil();
  }

  String _stripChatMlArtifacts(String raw) {
    var text = raw;
    final endIdx = text.indexOf(_imEnd);
    if (endIdx != -1) text = text.substring(0, endIdx);
    return text
        .replaceAll(_imStart, '')
        .replaceAll('<|endoftext|>', '')
        .replaceFirst(RegExp(r'^\s*assistant\s*'), '')
        .trim();
  }

  String _finish(String output, {required String via}) {
    PipelineLog.piiOutput(output, via: via);
    PipelineLog.done(
      _stage,
      message: via == 'regex' ? 'regex scrub applied' : 'LLM+regex scrub applied',
    );
    return output;
  }

}
