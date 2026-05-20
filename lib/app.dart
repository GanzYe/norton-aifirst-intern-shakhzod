import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/background/background_work_coordinator.dart';
import 'package:scam_message_detector/core/constants/app_branding.dart';
import 'package:scam_message_detector/core/routing/app_router.dart';
import 'package:scam_message_detector/core/theme/app_theme.dart';

class ScamMessageDetectorApp extends ConsumerWidget {
  const ScamMessageDetectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(backgroundWorkInitProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
