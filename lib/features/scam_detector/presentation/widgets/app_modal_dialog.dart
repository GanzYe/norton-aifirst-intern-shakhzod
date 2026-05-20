import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

enum AppModalTone { info, warning, danger }

class AppModalAction {
  const AppModalAction(
    this.label, {
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
}

/// Norton-styled modal dialog used across the app for confirmations and
/// warnings. Keeps the same card shape, yellow/red accents, and bold
/// outlined-button language as the rest of the surface.
class AppModalDialog extends StatelessWidget {
  const AppModalDialog({
    required this.title,
    required this.message,
    required this.actions,
    super.key,
    this.tone = AppModalTone.info,
    this.icon,
    this.extra,
  });

  final String title;
  final String message;
  final List<AppModalAction> actions;
  final AppModalTone tone;
  final IconData? icon;
  final Widget? extra;

  Color get _accent => switch (tone) {
    AppModalTone.info => AppColors.nortonYellow,
    AppModalTone.warning => AppColors.suspiciousOrange,
    AppModalTone.danger => AppColors.dangerousRed,
  };

  Color get _background => switch (tone) {
    AppModalTone.info => AppColors.surface,
    AppModalTone.warning => AppColors.warningBackground,
    AppModalTone.danger => AppColors.errorBackground,
  };

  IconData get _resolvedIcon =>
      icon ??
      switch (tone) {
        AppModalTone.info => Icons.info_outline,
        AppModalTone.warning => Icons.warning_amber_outlined,
        AppModalTone.danger => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: AppRadius.lgAll,
          border: Border.all(),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: AppSizes.borderThick * 2, color: _accent),
              Padding(
                padding: AppSpacing.card,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _resolvedIcon,
                          color: _accent,
                          size: AppSpacing.lg,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.resultCardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(message, style: AppTextStyles.resultBody),
                    if (extra != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      extra!,
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _ActionRow(actions: actions),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions});

  final List<AppModalAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.length == 1) {
      final action = actions.single;
      return SizedBox(
        width: double.infinity,
        height: AppSizes.analyzeButtonHeight,
        child: _buildButton(context, action),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(
            child: SizedBox(
              height: AppSizes.analyzeButtonHeight,
              child: _buildButton(context, actions[i]),
            ),
          ),
          if (i < actions.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildButton(BuildContext context, AppModalAction action) {
    if (action.isPrimary) {
      return OutlinedButton(
        onPressed: action.onPressed,
        style: Theme.of(context).outlinedButtonTheme.style,
        child: Text(action.label, style: AppTextStyles.analyzeButton),
      );
    }
    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: AppTextStyles.analyzeButton,
      ),
      child: Text(action.label),
    );
  }
}

/// Convenience: shows an [AppModalDialog] with a single "OK" button.
Future<void> showAppNoticeDialog(
  BuildContext context, {
  required String title,
  required String message,
  AppModalTone tone = AppModalTone.info,
  IconData? icon,
  String actionLabel = 'Got it',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppModalDialog(
      title: title,
      message: message,
      tone: tone,
      icon: icon,
      actions: [
        AppModalAction(
          actionLabel,
          isPrimary: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
