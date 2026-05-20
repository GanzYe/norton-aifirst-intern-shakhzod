import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/analysis_notes.dart';

/// Contextual notes above the message field (incognito / offline only).
class AnalysisNotesSection extends StatelessWidget {
  const AnalysisNotesSection({
    required this.incognito, required this.isOnline, super.key,
  });

  final bool incognito;
  final bool isOnline;

  bool get _showIncognitoNote => incognito;
  bool get _showOfflineNote => !isOnline;

  bool get hasVisibleNotes => _showIncognitoNote || _showOfflineNote;

  @override
  Widget build(BuildContext context) {
    if (!hasVisibleNotes) {
      return const SizedBox.shrink();
    }

    final muted = AppColors.resolveTextMuted(incognito: incognito);
    final border = AppColors.resolveBorder(incognito: incognito);
    final surface = AppColors.resolveSurfaceElevated(incognito: incognito);

    final notes = <Widget>[];

    if (_showIncognitoNote) {
      notes.add(
        _NoteCard(
          text: AnalysisNotes.incognito,
          muted: muted,
          border: border,
          surface: surface,
        ),
      );
    }
    if (_showOfflineNote) {
      if (notes.isNotEmpty) {
        notes.add(const SizedBox(height: AppSpacing.xs));
      }
      notes.add(
        _NoteCard(
          text: AnalysisNotes.offline,
          muted: muted,
          border: border,
          surface: surface,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: notes,
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.muted,
    required this.border,
    required this.surface,
  });

  final String text;
  final Color muted;
  final Color border;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          text,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: muted,
            fontSize: 12,
            height: AppSizes.subtitleLineHeight,
          ),
        ),
      ),
    );
  }
}
