import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'incognito_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class IncognitoMode extends _$IncognitoMode {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void setEnabled(bool enabled) => state = enabled;
}
