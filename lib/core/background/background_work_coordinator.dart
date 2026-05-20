import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/background/analysis_foreground_task_handler.dart';
import 'package:scam_message_detector/core/constants/app_branding.dart';
import 'package:scam_message_detector/core/notifications/app_notifications.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';

/// Initializes background download listeners and foreground-task helpers.
class BackgroundWorkCoordinator {
  BackgroundWorkCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<TaskUpdate>? _downloadSubscription;
  bool _downloadListenerAttached = false;

  Future<void> initialize() async {
    await AppNotifications.initialize();
    await AppNotifications.requestPermissionIfNeeded();
    _configureModelDownloadNotifications();
    _attachDownloadListener();
    await _initForegroundTask();
  }

  void dispose() {
    unawaited(_downloadSubscription?.cancel());
    _downloadSubscription = null;
    _downloadListenerAttached = false;
  }

  void _configureModelDownloadNotifications() {
    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Downloading AI model',
        '{filename} — {progress}',
      ),
      complete: const TaskNotification(
        'Local AI model ready',
        'Incognito mode is now available on this device.',
      ),
      error: const TaskNotification(
        'Model download failed',
        'Open the app to try again.',
      ),
      progressBar: true,
    );
  }

  void _attachDownloadListener() {
    if (_downloadListenerAttached) {
      return;
    }
    _downloadListenerAttached = true;
    _downloadSubscription = FileDownloader().updates.listen(_onDownloadUpdate);
  }

  Future<void> _onDownloadUpdate(TaskUpdate update) async {
    if (update.task.taskId != ModelDownloadService.backgroundTaskId) {
      return;
    }

    if (update is TaskProgressUpdate) {
      _ref.read(modelDownloadProgressProvider.notifier).state =
          update.progress;
      return;
    }

    if (update is! TaskStatusUpdate) {
      return;
    }

    switch (update.status) {
      case TaskStatus.complete:
        _ref.read(modelDownloadProgressProvider.notifier).state = null;
        _ref.read(incognitoModeControllerProvider.notifier).setEnabled(true);
        final inForeground = await FlutterForegroundTask.isAppOnForeground;
        if (!inForeground) {
          await AppNotifications.showModelDownloadComplete();
        }
      case TaskStatus.failed:
      case TaskStatus.notFound:
        _ref.read(modelDownloadProgressProvider.notifier).state = null;
        final inForeground = await FlutterForegroundTask.isAppOnForeground;
        if (!inForeground) {
          await AppNotifications.showModelDownloadFailed();
        }
      case TaskStatus.canceled:
        _ref.read(modelDownloadProgressProvider.notifier).state = null;
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.paused:
      case TaskStatus.waitingToRetry:
        break;
    }
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'smd_analysis_foreground',
        channelName: AppBranding.name,
        channelDescription: 'Shown while ${AppBranding.name} analyzes a message.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> startAnalysisForeground() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: '${AppBranding.name} analyzing',
      notificationText: 'Scam check in progress…',
      callback: analysisForegroundTaskCallback,
    );
  }

  Future<void> stopAnalysisForeground() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> notifyAnalysisFinished({
    required ScamAnalysis? analysis,
    Object? error,
  }) async {
    await stopAnalysisForeground();

    final inForeground = await FlutterForegroundTask.isAppOnForeground;
    if (inForeground) {
      return;
    }

    if (error != null) {
      final message = error is Exception ? error.toString() : null;
      await AppNotifications.showAnalysisFailed(message: message);
      return;
    }

    if (analysis == null ||
        analysis.localModelUnavailable ||
        analysis.localAnalysisFailed) {
      return;
    }

    await AppNotifications.showAnalysisComplete(
      riskLabel: analysis.riskLevel.label,
      confidence: analysis.confidence,
    );
  }
}

final backgroundWorkCoordinatorProvider = Provider<BackgroundWorkCoordinator>(
  (ref) {
    final coordinator = BackgroundWorkCoordinator(ref);
    ref.onDispose(coordinator.dispose);
    return coordinator;
  },
);

final backgroundWorkInitProvider = FutureProvider<void>((ref) async {
  await ref.read(backgroundWorkCoordinatorProvider).initialize();
});
