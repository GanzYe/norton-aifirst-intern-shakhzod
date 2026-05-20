import 'package:freezed_annotation/freezed_annotation.dart';

part 'soar_analysis_input.freezed.dart';

enum SoarInputKind { plainText, url, ipAddress, eml }

@freezed
abstract class SoarAnalysisInput with _$SoarAnalysisInput {
  const factory SoarAnalysisInput({
    required String rawContent,
    required SoarInputKind kind,
    @Default(false) bool incognitoEnabled,
    String? emlRawContent,
  }) = _SoarAnalysisInput;
}
