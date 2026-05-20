import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/core/notifications/app_notifications.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/screens/home_screen.dart';
import 'package:scam_message_detector/features/splash/presentation/splash_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  AppNotifications.bindNavigator(rootNavigatorKey);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (AppNotifications.consumeOpenHomeOnLaunch() &&
          state.matchedLocation == '/') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
}
