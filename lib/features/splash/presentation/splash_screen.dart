import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_message_detector/core/constants/app_branding.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/smd_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowStrength;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.splash,
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.38, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.elasticOut),
      ),
    );

    _glowStrength = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.55).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.7), weight: 35),
    ]).animate(_controller);

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.58, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _footerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.78, curve: Curves.easeIn),
      ),
    );

    unawaited(_controller.forward());
    unawaited(
      Future<void>.delayed(AppDurations.splashNavigate, () {
        if (!mounted) return;
        context.go('/home');
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _SplashAmbientPainter(
                  progress: _controller.value,
                  breathe: _glowStrength.value,
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SplashLogoStage(
                              logoOpacity: _logoOpacity.value,
                              logoScale: _logoScale.value,
                              glowStrength: _glowStrength.value,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            FadeTransition(
                              opacity: _taglineOpacity,
                              child: SlideTransition(
                                position: _taglineSlide,
                                child: Text(
                                  AppBranding.tagline,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.splashSubtitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.splashFooterBottom,
                      child: FadeTransition(
                        opacity: _footerOpacity,
                        child: Text(
                          AppBranding.attribution,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.splashFooter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashLogoStage extends StatelessWidget {
  const _SplashLogoStage({
    required this.logoOpacity,
    required this.logoScale,
    required this.glowStrength,
  });

  final double logoOpacity;
  final double logoScale;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final glowSize =
        AppSizes.splashGlowSize * lerpDouble(0.85, 1.08, glowStrength)!;

    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.22 * glowStrength,
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.nortonYellow.withValues(alpha: 0.55),
                    AppColors.nortonYellow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: logoOpacity,
            child: Transform.scale(
              scale: logoScale,
              child: const SmdLogo(
                size: AppSizes.logoSplash,
                semanticLabel: AppBranding.name,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft Norton-yellow ambient motion behind the splash content.
class _SplashAmbientPainter extends CustomPainter {
  _SplashAmbientPainter({
    required this.progress,
    required this.breathe,
  });

  final double progress;
  final double breathe;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress * math.pi * 2;

    void blob({
      required double cx,
      required double cy,
      required double radius,
      required double alpha,
      required double phase,
    }) {
      final drift = math.sin(t + phase) * 18;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.nortonYellow.withValues(alpha: alpha * breathe),
            AppColors.nortonYellow.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(cx + drift, cy - drift * 0.4),
            radius: radius,
          ),
        );
      canvas.drawCircle(Offset(cx + drift, cy), radius, paint);
    }

    blob(
      cx: w * 0.22,
      cy: h * 0.28,
      radius: w * 0.34,
      alpha: 0.14,
      phase: 0,
    );
    blob(
      cx: w * 0.78,
      cy: h * 0.62,
      radius: w * 0.28,
      alpha: 0.1,
      phase: 1.4,
    );
    blob(
      cx: w * 0.5,
      cy: h * 0.88,
      radius: w * 0.22,
      alpha: 0.08,
      phase: 2.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.breathe != breathe;
  }
}
