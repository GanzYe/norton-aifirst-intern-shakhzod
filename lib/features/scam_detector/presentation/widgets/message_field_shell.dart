import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';

/// Shared bordered surface for the message input and analysis loader.
///
/// Uses a single [BoxDecoration] fill + [Clip.antiAliasWithSaveLayer] so the
/// stroke and rounded corners composite cleanly without a white fringe.
class MessageFieldShell extends StatelessWidget {
  const MessageFieldShell({
    super.key,
    required this.incognito,
    required this.focused,
    required this.child,
  });

  final bool incognito;
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.incognitoTransition,
      curve: Curves.easeOut,
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: AppSizes.inputFieldMinHeight,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: AppDecorations.messageField(
        incognito: incognito,
        focused: focused,
      ),
      child: child,
    );
  }
}
