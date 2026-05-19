import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/input_classifier.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/soar_providers.dart';

part 'scam_analysis_controller.g.dart';

@riverpod
class ScamAnalysisController extends _$ScamAnalysisController {
  @override
  AsyncValue<ScamAnalysis?> build() => const AsyncData(null);

  Future<void> analyze({
    required String message,
    String? emlRawContent,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      try {
        final incognito = ref.read(incognitoModeControllerProvider);
        final kind = emlRawContent != null
            ? SoarInputKind.eml
            : InputClassifier.classify(message);

        return ref.read(orchestrateScamAnalysisUseCaseProvider).call(
              SoarAnalysisInput(
                rawContent: message,
                kind: kind,
                incognitoEnabled: incognito,
                emlRawContent: emlRawContent,
              ),
            );
      } on AnalyzeMessageException catch (e) {
        throw AnalysisFailedException(e.message);
      } on GeminiDataSourceException catch (e) {
        throw AnalysisFailedException(e.message);
      }
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}

class AnalysisFailedException implements Exception {
  const AnalysisFailedException(this.message);

  final String message;

  @override
  String toString() => message;
}
