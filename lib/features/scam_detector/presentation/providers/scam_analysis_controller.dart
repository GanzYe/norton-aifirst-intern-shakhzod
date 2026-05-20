import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/core/background/background_work_coordinator.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/soar_analysis_input.dart';
import 'package:scam_message_detector/features/scam_detector/domain/utils/input_classifier.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/soar_providers.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/utils/friendly_error.dart';

part 'scam_analysis_controller.g.dart';

@riverpod
class ScamAnalysisController extends _$ScamAnalysisController {
  @override
  AsyncValue<ScamAnalysis?> build() => const AsyncData(null);

  Future<void> analyze({required String message, String? emlRawContent}) async {
    state = const AsyncLoading();

    final background = ref.read(backgroundWorkCoordinatorProvider);

    state = await AsyncValue.guard(() async {
      try {
        final incognito = ref.read(incognitoModeControllerProvider);
        final kind = emlRawContent != null
            ? SoarInputKind.eml
            : InputClassifier.classify(message);

        return ref
            .read(orchestrateScamAnalysisUseCaseProvider)
            .call(
              SoarAnalysisInput(
                rawContent: message,
                kind: kind,
                incognitoEnabled: incognito,
                emlRawContent: emlRawContent,
              ),
            );
      } on Object catch (error, stack) {
        // Always normalize whatever the pipeline threw into a clean,
        // user-facing message. No PlatformException / Dio / API quota
        // strings ever reach the UI.
        developer.log(
          'Analyze failed',
          name: 'ScamAnalysisController',
          error: error,
          stackTrace: stack,
        );
        throw AnalysisFailedException(friendlyAnalysisError(error));
      }
    });

    await background.notifyAnalysisFinished(
      analysis: state.valueOrNull,
      error: state.hasError ? state.error : null,
    );
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
