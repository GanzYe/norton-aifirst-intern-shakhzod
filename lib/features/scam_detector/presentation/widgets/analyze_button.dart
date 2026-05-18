import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

class AnalyzeButton extends StatelessWidget {
  const AnalyzeButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.analyzeButtonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: Theme.of(context).outlinedButtonTheme.style,
        child: isLoading
            ? const SizedBox(
                width: AppSizes.progressIndicator,
                height: AppSizes.progressIndicator,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.progressStroke,
                  color: AppColors.textPrimary,
                ),
              )
            : const Text('Analyze', style: AppTextStyles.analyzeButton),
      ),
    );
  }
}
