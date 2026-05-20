import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';

/// Section label above the horizontally scrolling example chips.
class ExampleSamplesHeader extends StatelessWidget {
  const ExampleSamplesHeader({required this.incognito, super.key});

  final bool incognito;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.resolveTextMuted(incognito: incognito);

    return Row(
      children: [
        Text(
          'Example message',
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
    );
  }
}

/// Full-width horizontal chip strip.
///
/// Place in a sliver without horizontal padding.
class ExampleSamplesChipStrip extends StatelessWidget {
  const ExampleSamplesChipStrip({
    required this.incognito,
    required this.enabled,
    required this.onSampleTap,
    super.key,
  });

  final bool incognito;
  final bool enabled;
  final void Function(String body) onSampleTap;

  static const _contentInset = AppSpacing.lg;

  /// Chip height + vertical padding inside each chip.
  static const double stripHeight = 40;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.resolveTextPrimary(incognito: incognito);

    return SizedBox(
      height: stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _contentInset),
        itemCount: ExampleMessages.samples.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final sample = ExampleMessages.samples[index];
          return _ExampleChip(
            label: sample.title,
            incognito: incognito,
            enabled: enabled,
            onTap: () => onSampleTap(sample.body),
            textColor: primary,
          );
        },
      ),
    );
  }
}

/// Back-compat wrapper when header and strip share parent padding.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExampleSamplesHeader(incognito: incognito),
        const SizedBox(height: AppSpacing.xs),
        ExampleSamplesChipStrip(
          incognito: incognito,
          enabled: enabled,
          onSampleTap: onSampleTap,
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
