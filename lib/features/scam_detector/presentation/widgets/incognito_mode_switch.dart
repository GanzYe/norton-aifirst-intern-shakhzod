import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/app_modal_dialog.dart';

/// Toggle for on-device / private analysis with a subtle privacy accent when on.
class IncognitoModeSwitch extends ConsumerWidget {
  const IncognitoModeSwitch({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incognito = ref.watch(incognitoModeControllerProvider);
    final downloadProgress = ref.watch(modelDownloadProgressProvider);
    final isDownloading = downloadProgress != null;
    final switchEnabled = enabled && !isDownloading;

    final surface = AppColors.resolveSurfaceElevated(incognito: incognito);
    final border = AppColors.resolveBorder(incognito: incognito);
    final primary = AppColors.resolveTextPrimary(incognito: incognito);
    final muted = AppColors.resolveTextMuted(incognito: incognito);

    return AnimatedContainer(
      duration: AppDurations.incognitoTransition,
      curve: Curves.easeOutCubic,
      padding: AppSpacing.incognitoSwitchPadding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: AppDurations.incognitoTransition,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: incognito
                      ? AppColors.nortonYellow.withValues(alpha: 0.22)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: incognito
                        ? AppColors.nortonYellow.withValues(alpha: 0.55)
                        : border,
                  ),
                ),
                child: Icon(
                  incognito ? Icons.shield_rounded : Icons.shield_outlined,
                  size: 20,
                  color: incognito ? AppColors.textPrimary : muted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incognito mode',
                      style: AppTextStyles.incognitoTitle.copyWith(
                        color: primary,
                      ),
                    ),
                    Text(
                      isDownloading
                          ? 'Downloading the on-device model (~1 GB)…'
                          : incognito
                          ? 'On — messages stay on your phone'
                          : 'Off — uses cloud AI when online',
                      style: AppTextStyles.incognitoSubtitle.copyWith(
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: incognito || isDownloading,
                onChanged: switchEnabled
                    ? (value) => _onChanged(context, ref, value)
                    : null,
              ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: downloadProgress,
              color: AppColors.nortonYellow,
              backgroundColor: AppColors.borderMuted,
              borderRadius: AppRadius.smAll,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final controller = ref.read(incognitoModeControllerProvider.notifier);

    if (!value) {
      controller.disable();
      return;
    }

    final service = ref.read(modelDownloadServiceProvider);
    if (await service.isModelDownloaded()) {
      controller.enable();
      return;
    }

    if (!context.mounted) {
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppModalDialog(
        title: 'Download local AI model?',
        icon: Icons.download_outlined,
        message:
            'Incognito Mode uses an on-device AI model so your messages '
            'never leave the phone. The model is about 1 GB and downloads '
            "in the background—you can close the app and we'll notify you "
            "when it's ready.",
        actions: [
          AppModalAction(
            'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppModalAction(
            'Download',
            isPrimary: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (proceed != true || !context.mounted) {
      return;
    }

    try {
      await controller.downloadAndEnableInBackground();
    } on ModelDownloadException catch (e) {
      if (!context.mounted) {
        return;
      }
      await showAppNoticeDialog(
        context,
        title: 'Download failed',
        message: e.message,
        tone: AppModalTone.danger,
      );
    } on Object {
      if (!context.mounted) {
        return;
      }
      await showAppNoticeDialog(
        context,
        title: 'Download failed',
        message: 'Model download failed. Please try again.',
        tone: AppModalTone.danger,
      );
    }
  }
}
