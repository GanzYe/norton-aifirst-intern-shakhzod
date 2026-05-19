import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/app_modal_dialog.dart';

class IncognitoModeSwitch extends ConsumerWidget {
  const IncognitoModeSwitch({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incognito = ref.watch(incognitoModeControllerProvider);
    final downloadProgress = ref.watch(modelDownloadProgressProvider);
    final isDownloading = downloadProgress != null;
    final switchEnabled = enabled && !isDownloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Incognito mode',
            style: AppTextStyles.sectionLabel,
          ),
          subtitle: const Text(
            'On-device PII scrubbing; skips OSINT on plain text to avoid '
            'leaks.',
            style: AppTextStyles.homeSubtitle,
          ),
          value: incognito,
          onChanged: switchEnabled
              ? (value) => _onChanged(context, ref, value)
              : null,
        ),
        if (isDownloading) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(value: downloadProgress),
        ],
      ],
    );
  }

  Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final controller = ref.read(incognitoModeControllerProvider.notifier);

    if (!value) {
      controller.toggleOff();
      return;
    }

    final service = ref.read(modelDownloadServiceProvider);
    if (await service.isModelDownloaded()) {
      controller.setEnabled(true);
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
            'never leave the phone. The model is about 350 MB and only '
            'needs to be downloaded once.',
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
      await controller.downloadAndEnable();
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
