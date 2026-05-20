import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

/// Composite input: text area + `.eml` (bottom-left) + Analyze (bottom-right).
/// Analyze expands from right → left when the user starts typing.
class MessageInputField extends StatefulWidget {
  const MessageInputField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.incognito,
    required this.onAnalyze,
    required this.onPickEml,
    required this.onClearEml,
    required this.attachedEmlName,
    this.onFocusChanged,
    this.hintText =
        'Enter a URL, message, email, or snippet to check for scams.',
  });

  final TextEditingController controller;
  final bool enabled;
  final bool incognito;
  final VoidCallback onAnalyze;
  final VoidCallback onPickEml;
  final VoidCallback onClearEml;
  final String? attachedEmlName;
  final ValueChanged<bool>? onFocusChanged;
  final String hintText;

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  late final FocusNode _focusNode;
  bool _hasText = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant MessageInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
      _handleTextChange();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _focused) {
      setState(() => _focused = hasFocus);
      widget.onFocusChanged?.call(hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAnalyze = _hasText && widget.enabled;
    final textPrimary =
        AppColors.resolveTextPrimary(incognito: widget.incognito);
    final hintColor = AppColors.resolveHint(incognito: widget.incognito);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Padding(
            padding: AppSpacing.inputFieldText,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              maxLines: null,
              minLines: 5,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: textPrimary),
              cursorColor: AppColors.nortonYellow,
              decoration: AppDecorations.inlineInputField(
                hintText: widget.hintText,
              ).copyWith(
                hintStyle: AppTextStyles.inputHint.copyWith(color: hintColor),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.inputBottomBarMinHeight,
            ),
            child: Padding(
              padding: AppSpacing.inputFieldActions,
              child: Row(
                children: [
                  _EmlControl(
                    enabled: widget.enabled,
                    incognito: widget.incognito,
                    attachedName: widget.attachedEmlName,
                    onPick: widget.onPickEml,
                    onClear: widget.onClearEml,
                  ),
                  const Spacer(),
                  _InlineAnalyzeButton(
                    visible: showAnalyze,
                    onPressed: widget.onAnalyze,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmlControl extends StatelessWidget {
  const _EmlControl({
    required this.enabled,
    required this.incognito,
    required this.attachedName,
    required this.onPick,
    required this.onClear,
  });

  final bool enabled;
  final bool incognito;
  final String? attachedName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final name = attachedName;
    if (name != null) {
      return _EmlAttachedChip(
        filename: name,
        enabled: enabled,
        incognito: incognito,
        onClear: onClear,
      );
    }
    return _EmlUploadButton(
      enabled: enabled,
      incognito: incognito,
      onPressed: onPick,
    );
  }
}

class _EmlUploadButton extends StatelessWidget {
  const _EmlUploadButton({
    required this.enabled,
    required this.incognito,
    required this.onPressed,
  });

  final bool enabled;
  final bool incognito;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? AppColors.resolveTextPrimary(incognito: incognito)
        : AppColors.disabledTextPrimary;

    return Material(
      color: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadius.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_email_outlined,
                size: AppSizes.inputInlineIcon,
                color: fg,
              ),
              const SizedBox(width: 4),
              Text('.eml', style: AppTextStyles.inlineEmlButton.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmlAttachedChip extends StatelessWidget {
  const _EmlAttachedChip({
    required this.filename,
    required this.enabled,
    required this.incognito,
    required this.onClear,
  });

  final String filename;
  final bool enabled;
  final bool incognito;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.resolveTextPrimary(incognito: incognito);
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      decoration: BoxDecoration(
        color: AppColors.nortonYellow.withValues(
          alpha: AppColors.opacityRiskFill,
        ),
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: AppColors.resolveBorder(incognito: incognito),
          width: AppSizes.borderThin,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.email_outlined,
            size: AppSizes.inputInlineIcon,
            color: fg,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.inlineEmlButton.copyWith(color: fg),
            ),
          ),
          InkWell(
            onTap: enabled ? onClear : null,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: AppSizes.inputInlineIcon,
                color: enabled ? fg : AppColors.disabledTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAnalyzeButton extends StatefulWidget {
  const _InlineAnalyzeButton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  State<_InlineAnalyzeButton> createState() => _InlineAnalyzeButtonState();
}

class _InlineAnalyzeButtonState extends State<_InlineAnalyzeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _width;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.analyzeButtonBirth,
    );
    _width = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.visible) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _InlineAnalyzeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward(from: 0);
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputInlineButtonHeight,
      child: AnimatedBuilder(
        animation: _width,
        builder: (context, child) {
          if (_width.value == 0) {
            return const SizedBox.shrink();
          }
          return ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: _width.value,
              child: child,
            ),
          );
        },
        child: SizedBox(
          height: AppSizes.inputInlineButtonHeight,
          child: ElevatedButton(
            onPressed: widget.visible ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nortonYellow,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shadowColor: AppColors.transparent,
              surfaceTintColor: AppColors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, AppSizes.inputInlineButtonHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(
                color: AppColors.borderBlack,
                width: AppSizes.borderMedium,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              textStyle: AppTextStyles.inlineAnalyzeButton,
            ),
            child: const Text(
              'Analyze',
              style: AppTextStyles.inlineAnalyzeButton,
            ),
          ),
        ),
      ),
    );
  }
}
