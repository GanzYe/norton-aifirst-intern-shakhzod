import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

/// Small SMD shield letter-mark for the app bar.
class SmdLogo extends StatelessWidget {
  const SmdLogo({super.key, this.size = AppSizes.logoDefault});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SmdShieldPainter(),
    );
  }
}

class _SmdShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.82, h * 0.72)
      ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.18, h * 0.72)
      ..lineTo(w * 0.08, h * 0.22)
      ..close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = AppColors.nortonYellow
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = AppColors.borderBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.logoStroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SMD',
        style: AppTextStyles.logoMark.copyWith(
          fontSize: w * AppSizes.logoTextScale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        h * 0.38 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
