abstract final class AppDurations {
  static const Duration resultAnimation = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 2800);
  static const Duration splashNavigate = Duration(milliseconds: 3000);

  // Inline Analyze button "birth" animation when the user starts typing.
  static const Duration analyzeButtonBirth = Duration(milliseconds: 360);

  // Theme tint transition when toggling Incognito mode.
  static const Duration incognitoTransition = Duration(milliseconds: 320);

  // Input ↔ loader crossfade on the home screen.
  static const Duration loaderCrossfade = Duration(milliseconds: 160);

  // AnalysisLoadingIndicator timing.
  static const Duration loaderFadeIn = Duration(milliseconds: 320);
  static const Duration loaderMeshCycle = Duration(milliseconds: 4800);
  static const Duration loaderShimmer = Duration(milliseconds: 2000);
  static const Duration loaderPhaseCycle = Duration(milliseconds: 3600);
}
