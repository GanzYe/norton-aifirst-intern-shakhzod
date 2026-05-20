import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/app.dart';
import 'package:scam_message_detector/core/notifications/app_notifications.dart';
import 'package:scam_message_detector/core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  AppNotifications.bindNavigator(rootNavigatorKey);
  await AppNotifications.initialize();
  await AppNotifications.captureLaunchNotification();

  runApp(const ProviderScope(child: ScamMessageDetectorApp()));
}
