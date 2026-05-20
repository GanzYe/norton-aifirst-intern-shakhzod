import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini model id used for scam message analysis.
const geminiScamDetectorModelId = 'gemini-2.5-flash-lite';

/// JSON schema enforced by the API via [GenerationConfig.responseSchema].
final scamAnalysisResponseSchema = Schema.object(
  properties: {
    'risk_level': Schema.enumString(
      enumValues: ['SAFE', 'SUSPICIOUS', 'DANGEROUS'],
      description: 'Assessed scam, phishing, or fraud risk level.',
    ),
    'confidence': Schema.integer(
      description: 'Confidence score from 0 to 100.',
    ),
    'explanation': Schema.string(
      description: 'Two to three sentences explaining the assessment.',
    ),
  },
  requiredProperties: ['risk_level', 'confidence', 'explanation'],
);

final scamAnalysisSystemInstruction = Content.system('''
You are a cybersecurity expert analyzing messages for scam, phishing, and fraud risk.
Rules:
- SAFE: legitimate or low-risk content
- SUSPICIOUS: urgency, impersonation, odd links, or prize/lottery patterns
- DANGEROUS: clear phishing, credential theft, malware links, or financial fraud
''');

/// Builds a [GenerativeModel] with structured JSON output for scam analysis.
GenerativeModel createScamAnalysisGenerativeModel(String apiKey) {
  return GenerativeModel(
    model: geminiScamDetectorModelId,
    apiKey: apiKey,
    systemInstruction: scamAnalysisSystemInstruction,
    generationConfig: GenerationConfig(
      maxOutputTokens: 512,
      temperature: 0.2,
      responseMimeType: 'application/json',
      responseSchema: scamAnalysisResponseSchema,
    ),
  );
}
