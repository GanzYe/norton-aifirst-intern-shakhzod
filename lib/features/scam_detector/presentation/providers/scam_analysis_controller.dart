import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/anthropic_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_detector_providers.dart';

part 'scam_analysis_controller.g.dart';

@riverpod
class ScamAnalysisController extends _$ScamAnalysisController {
  @override
  AsyncValue<ScamAnalysis?> build() => const AsyncData(null);

  Future<void> analyze(String message) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      try {
        return await ref.read(analyzeMessageUseCaseProvider).call(message);
      } on AnalyzeMessageException catch (e) {
        throw AnalysisFailedException(e.message);
      } on AnthropicDataSourceException catch (e) {
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
