import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _abbrevOpacity;
  late final Animation<double> _abbrevScale;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.splash,
    );

    _titleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.55,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
    ]).animate(_controller);

    _titleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
    ]).animate(_controller);

    _abbrevOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 38),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 22,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_controller);

    _abbrevScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 38),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.7,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_controller);

    _subtitleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_controller);

    _footerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
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
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: AppSizes.splashTitleArea,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _SplashTitleLayer(
                              opacity: _titleOpacity,
                              scale: _titleScale,
                              child: const Text(
                                'Scam Message Detector',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.splashTitle,
                              ),
                            ),
                            _SplashTitleLayer(
                              opacity: _abbrevOpacity,
                              scale: _abbrevScale,
                              child: const Text(
                                'SMD.',
                                style: AppTextStyles.splashAbbrev,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: const Text(
                          'norton intern',
                          style: AppTextStyles.splashSubtitle,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.splashFooterBottom,
              child: FadeTransition(
                opacity: _footerOpacity,
                child: const Text(
                  'by Shakhzod',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.splashFooter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashTitleLayer extends StatelessWidget {
  const _SplashTitleLayer({
    required this.opacity,
    required this.scale,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<double> scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.value,
      child: Transform.scale(scale: scale.value, child: child),
    );
  }
}
