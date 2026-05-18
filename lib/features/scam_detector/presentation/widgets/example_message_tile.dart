import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

class ExampleMessageTile extends StatelessWidget {
  const ExampleMessageTile({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: AppSpacing.exampleTile,
          decoration: AppDecorations.exampleTile(
            borderColor: AppColors.borderMuted,
          ),
          child: Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: AppSizes.iconExample,
                color: AppColors.iconMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.exampleTile)),
            ],
          ),
        ),
      ),
    );
  }
}
