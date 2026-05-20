import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/background/background_work_coordinator.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_analysis_controller.dart';

/// Starts the analysis foreground service only when the user leaves the app
/// mid-analysis — never on Analyze tap (that blocked the loader transition).
class AnalysisBackgroundLifecycle extends ConsumerStatefulWidget {
  const AnalysisBackgroundLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AnalysisBackgroundLifecycle> createState() =>
      _AnalysisBackgroundLifecycleState();
}

class _AnalysisBackgroundLifecycleState
    extends ConsumerState<AnalysisBackgroundLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(scamAnalysisControllerProvider).isLoading) {
      return;
    }

    final background = ref.read(backgroundWorkCoordinatorProvider);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(background.startAnalysisForeground());
      case AppLifecycleState.resumed:
        unawaited(background.stopAnalysisForeground());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
