import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_message_detector/core/constants/app_branding.dart';

/// Local notifications for background work completion.
abstract final class AppNotifications {
  static const _channelId = 'smd_background';
  static const _channelName = AppBranding.name;
  static const _channelDescription =
      'Alerts when model downloads or scam analysis finish in the background.';

  static const _openHomePayload = 'open_home';

  static const modelDownloadNotificationId = 1001;
  static const analysisCompleteNotificationId = 1002;
  static const analysisFailedNotificationId = 1003;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _initialized = false;
  static bool _openHomeOnLaunch = false;

  static void bindNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Call once at startup before [runApp] to detect cold-start from a tap.
  static Future<void> captureLaunchNotification() async {
    if (!_initialized) {
      await initialize();
    }
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _openHomeOnLaunch = true;
    }
  }

  /// Consumed by [GoRouter.redirect] to skip splash when opened from a notification.
  static bool consumeOpenHomeOnLaunch() {
    if (!_openHomeOnLaunch) {
      return false;
    }
    _openHomeOnLaunch = false;
    return true;
  }

  static Future<void> requestPermissionIfNeeded() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> showModelDownloadComplete() async {
    await _show(
      id: modelDownloadNotificationId,
      title: '${AppBranding.name} model ready',
      body:
          'On-device AI is installed. Incognito mode is ready for private analysis.',
    );
  }

  static Future<void> showModelDownloadFailed() async {
    await _show(
      id: modelDownloadNotificationId,
      title: '${AppBranding.name} download failed',
      body: 'Could not download the on-device AI model. Tap to retry in the app.',
    );
  }

  static Future<void> showAnalysisComplete({
    required String riskLabel,
    required int confidence,
  }) async {
    await _show(
      id: analysisCompleteNotificationId,
      title: '${AppBranding.name} analysis complete',
      body: 'Risk: $riskLabel · $confidence% confidence. Tap to view details.',
    );
  }

  static Future<void> showAnalysisFailed({String? message}) async {
    await _show(
      id: analysisFailedNotificationId,
      title: '${AppBranding.name} analysis failed',
      body: message ?? 'Something went wrong. Tap to open the app and try again.',
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    _openHome();
  }

  static void _openHome() {
    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) {
      _openHomeOnLaunch = true;
      return;
    }
    GoRouter.of(context).go('/home');
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: _openHomePayload,
      notificationDetails: details,
    );
  }
}
