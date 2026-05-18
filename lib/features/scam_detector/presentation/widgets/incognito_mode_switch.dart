import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';

class IncognitoModeSwitch extends ConsumerWidget {
  const IncognitoModeSwitch({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incognito = ref.watch(incognitoModeProvider);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Incognito mode', style: AppTextStyles.sectionLabel),
      subtitle: const Text(
        'On-device PII scrubbing; skips OSINT on plain text to avoid leaks.',
        style: AppTextStyles.homeSubtitle,
      ),
      value: incognito,
      onChanged: enabled
          ? (_) => ref.read(incognitoModeProvider.notifier).toggle()
          : null,
    );
  }
}
