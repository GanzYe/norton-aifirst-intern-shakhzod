import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';

part 'incognito_mode_provider.g.dart';

final modelDownloadProgressProvider = StateProvider<double?>((ref) => null);

@Riverpod(keepAlive: true)
ModelDownloadService modelDownloadService(ModelDownloadServiceRef ref) {
  return ModelDownloadService();
}

@Riverpod(keepAlive: true)
class IncognitoModeController extends _$IncognitoModeController {
  @override
  bool build() => false;

  void toggleOff() => state = false;

  void setEnabled(bool enabled) => state = enabled;

  /// Starts a background download; progress and completion are handled by
  /// [BackgroundWorkCoordinator].
  Future<void> downloadAndEnableInBackground() async {
    ref.read(modelDownloadProgressProvider.notifier).state = 0;
    final service = ref.read(modelDownloadServiceProvider);
    if (await service.isModelDownloaded()) {
      ref.read(modelDownloadProgressProvider.notifier).state = null;
      state = true;
      return;
    }
    await service.downloadModelInBackground();
  }
}
