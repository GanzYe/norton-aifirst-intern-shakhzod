import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';

/// Compact horizontal sample picker — replaces tall stacked example tiles.
class ExampleSamplesRow extends StatelessWidget {
  const ExampleSamplesRow({
    required this.incognito,
    required this.enabled,
    required this.onSampleTap,
    super.key,
  });

  final bool incognito;
  final bool enabled;
  final void Function(String body) onSampleTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.resolveTextMuted(incognito: incognito);
    final primary = AppColors.resolveTextPrimary(incognito: incognito);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Sample messages',
              style: AppTextStyles.sectionLabel.copyWith(color: muted),
            ),
            const Spacer(),
            Text(
              'Tap to try one',
              style: AppTextStyles.sectionLabel.copyWith(
                color: muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExampleMessages.samples.map((sample) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _ExampleChip(
                  label: sample.title,
                  incognito: incognito,
                  enabled: enabled,
                  onTap: () => onSampleTap(sample.body),
                  textColor: primary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({
    required this.label,
    required this.incognito,
    required this.enabled,
    required this.onTap,
    required this.textColor,
  });

  final String label;
  final bool incognito;
  final bool enabled;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.pillAll,
        child: Ink(
          decoration: AppDecorations.exampleChip(
            incognito: incognito,
            selected: false,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: AppTextStyles.exampleChip.copyWith(
              color: enabled ? textColor : AppColors.disabledTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
