import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';

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
          title: const Text('Incognito mode', style: AppTextStyles.sectionLabel),
          subtitle: const Text(
            'On-device PII scrubbing; skips OSINT on plain text to avoid leaks.',
            style: AppTextStyles.homeSubtitle,
          ),
          value: incognito,
          onChanged: switchEnabled ? (value) => _onChanged(context, ref, value) : null,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Download Local AI Model?'),
        content: const Text(
          'To use Incognito Mode with maximum accuracy, the app needs to '
          'download a local AI model (~350MB). This happens only once. '
          'Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Download'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model download failed.')),
      );
    }
  }
}
