import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/constants/app_branding.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';

/// SMD brand mark from [assetPath] — app bar, splash, and other chrome.
class SmdLogo extends StatelessWidget {
  const SmdLogo({
    super.key,
    this.size = AppSizes.logoDefault,
    this.semanticLabel = AppBranding.name,
  });

  static const String assetPath = 'assets/images/smd_logo.png';

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
    );
  }
}
