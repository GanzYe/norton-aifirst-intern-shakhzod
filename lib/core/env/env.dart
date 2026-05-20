import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract final class Env {
  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true)
  static final String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(varName: 'GROQ_API_KEY', obfuscate: true, defaultValue: '')
  static final String groqApiKey = _Env.groqApiKey;

  @EnviedField(varName: 'VIRUSTOTAL_API_KEY', obfuscate: true, defaultValue: '')
  static final String virusTotalApiKey = _Env.virusTotalApiKey;

  @EnviedField(varName: 'ABUSEIPDB_API_KEY', obfuscate: true, defaultValue: '')
  static final String abuseIpdbApiKey = _Env.abuseIpdbApiKey;

  @EnviedField(varName: 'URLSCAN_API_KEY', obfuscate: true, defaultValue: '')
  static final String urlScanApiKey = _Env.urlScanApiKey;
}
