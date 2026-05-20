import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

/// Aurora blobs behind centered copy. Fills [MessageFieldShell] — same size as
/// the input field (no fixed height).
class AnalysisLoadingIndicator extends StatefulWidget {
  const AnalysisLoadingIndicator({
    super.key,
    required this.incognito,
    this.animate = true,
    this.title = "We're analyzing your message",
    this.subtitle =
        'Our AI is reading what you wrote and checking it for scam signals…',
  });

  final bool incognito;

  /// When false, animation tickers are paused (loader hidden via opacity).
  final bool animate;
  final String title;
  final String subtitle;

  @override
  State<AnalysisLoadingIndicator> createState() =>
      _AnalysisLoadingIndicatorState();
}

class _AnalysisLoadingIndicatorState extends State<AnalysisLoadingIndicator>
    with TickerProviderStateMixin {
  static const _phases = [
    'Reading your message',
    'Scanning for scam patterns',
    'Running AI safety checks',
  ];

  late final AnimationController _meshController;
  late final AnimationController _shimmerController;
  late final AnimationController _phaseController;
  int _phaseIndex = 0;
  bool _effectsReady = false;

  @override
  void initState() {
    super.initState();
    _meshController = AnimationController(
      vsync: this,
      duration: AppDurations.loaderMeshCycle,
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: AppDurations.loaderShimmer,
    );
    _phaseController = AnimationController(
      vsync: this,
      duration: AppDurations.loaderPhaseCycle,
    )..addListener(_onPhaseTick);
    // Paint static copy on the first frame; start aurora on the next so the
    // input→loader transition stays smooth on mid-range devices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _effectsReady = true);
      _setAnimating(widget.animate);
    });
  }

  @override
  void didUpdateWidget(covariant AnalysisLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate && _effectsReady) {
      _setAnimating(widget.animate);
    }
  }

  void _setAnimating(bool animating) {
    if (animating) {
      _meshController.repeat();
      _shimmerController.repeat();
      _phaseController.repeat();
      return;
    }
    _meshController.stop();
    _shimmerController.stop();
    _phaseController.stop();
  }

  void _onPhaseTick() {
    final index =
        (_phaseController.value * _phases.length).floor() % _phases.length;
    if (index != _phaseIndex) {
      setState(() => _phaseIndex = index);
    }
  }

  @override
  void dispose() {
    _phaseController.removeListener(_onPhaseTick);
    _meshController.dispose();
    _shimmerController.dispose();
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.resolveTextPrimary(
      incognito: widget.incognito,
    );
    final textMuted = AppColors.resolveTextMuted(incognito: widget.incognito);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_effectsReady)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _meshController,
              builder: (context, _) => CustomPaint(
                isComplex: true,
                willChange: true,
                painter: _AuroraBlobsPainter(
                  meshT: _meshController.value,
                  incognito: widget.incognito,
                ),
              ),
            ),
          ),
        Center(
          child: Padding(
            padding: AppSpacing.loaderContent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.loaderContentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.loaderTitle.copyWith(
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.loaderSubtitleTop),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.loaderSubtitle.copyWith(
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      _phases[_phaseIndex],
                      key: ValueKey<int>(_phaseIndex),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.loaderPhase,
                    ),
                  ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_effectsReady)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) => _MinimalProgressBar(
                            progress: _shimmerController.value,
                            incognito: widget.incognito,
                          ),
                        ),
                      )
                    else
                      _MinimalProgressBar(
                        progress: 0.35,
                        incognito: widget.incognito,
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Original drifting aurora blobs — visible in light and dark modes.
class _AuroraBlobsPainter extends CustomPainter {
  _AuroraBlobsPainter({required this.meshT, required this.incognito});

  static const _incognitoLoaderBoost = 1.15;

  final double meshT;
  final bool incognito;

  @override
  void paint(Canvas canvas, Size size) {
    // Card fill comes from [MessageFieldShell] decoration; only blobs painted here.
    final blobs = <_Blob>[
      _Blob(
        AppColors.loaderGlow,
        Offset(
          size.width * (0.2 + 0.15 * math.sin(meshT * 2 * math.pi)),
          size.height * (0.25 + 0.1 * math.cos(meshT * 2 * math.pi)),
        ),
        size.width * 0.55,
      ),
      _Blob(
        AppColors.loaderAccentViolet,
        Offset(
          size.width * (0.75 + 0.12 * math.cos(meshT * 2 * math.pi + 1)),
          size.height * (0.35 + 0.12 * math.sin(meshT * 2 * math.pi + 0.5)),
        ),
        size.width * 0.45,
      ),
      _Blob(
        AppColors.loaderAccentCyan,
        Offset(
          size.width * 0.5,
          size.height * (0.7 + 0.08 * math.sin(meshT * 2 * math.pi + 2)),
        ),
        size.width * 0.38,
      ),
    ];

    final peakAlpha = incognito
        ? AppColors.opacityLoaderMeshLight * _incognitoLoaderBoost
        : AppColors.opacityLoaderMeshLight;
    const blend = BlendMode.srcOver;

    for (final blob in blobs) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(blob.center, blob.radius, [
          blob.color.withValues(alpha: peakAlpha),
          blob.color.withValues(alpha: AppColors.opacitySweepFade),
        ])
        ..blendMode = blend;
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraBlobsPainter oldDelegate) =>
      oldDelegate.meshT != meshT || oldDelegate.incognito != incognito;
}

class _Blob {
  const _Blob(this.color, this.center, this.radius);

  final Color color;
  final Offset center;
  final double radius;
}

class _MinimalProgressBar extends StatelessWidget {
  const _MinimalProgressBar({required this.progress, required this.incognito});

  final double progress;
  final bool incognito;

  @override
  Widget build(BuildContext context) {
    final track = AppColors.resolveSurfaceElevated(incognito: incognito);
    final widthFactor = 0.28 + 0.22 * math.sin(progress * 2 * math.pi);

    return SizedBox(
      width: AppSizes.loaderProgressMaxWidth,
      height: AppSizes.loaderProgressHeight,
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: const ColoredBox(color: AppColors.nortonYellow),
            ),
          ],
        ),
      ),
    );
  }
}
