import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process alive while scam analysis runs (Android foreground service).
@pragma('vm:entry-point')
void analysisForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_AnalysisForegroundTaskHandler());
}

class _AnalysisForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
