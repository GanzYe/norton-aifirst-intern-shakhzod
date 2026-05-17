import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract final class Env {
  @EnviedField(varName: 'ANTHROPIC_API_KEY', obfuscate: true)
  static final String anthropicApiKey = _Env.anthropicApiKey;
}
