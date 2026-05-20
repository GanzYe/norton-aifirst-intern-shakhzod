import 'package:flutter/material.dart';
import 'package:scam_message_detector/core/logging/pipeline_log_entry.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_radius.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';

/// Expandable trace of SOAR pipeline stages (OSINT, PII, LLM, etc.).
class AnalysisPipelineLogPanel extends StatelessWidget {
  const AnalysisPipelineLogPanel({
    required this.entries,
    super.key,
  });

  final List<PipelineLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'No pipeline trace was recorded for this run.',
        style: AppTextStyles.homeSubtitle.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _LogEntryTile(entry: entries[i]),
        ],
      ],
    );
  }
}

class _LogEntryTile extends StatefulWidget {
  const _LogEntryTile({required this.entry});

  final PipelineLogEntry entry;

  @override
  State<_LogEntryTile> createState() => _LogEntryTileState();
}

class _LogEntryTileState extends State<_LogEntryTile> {
  var _detailExpanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final tagColor = _tagColor(entry.tag);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.smAll,
        border: Border.all(
          color: AppColors.borderBlack.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TagChip(label: entry.tag, color: tagColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    entry.stage,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SelectableText(
              entry.summaryLine,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.35,
                color: AppColors.textMuted,
              ),
            ),
            if (entry.hasDetail) ...[
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                onTap: () => setState(() => _detailExpanded = !_detailExpanded),
                borderRadius: AppRadius.smAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        _detailExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _detailExpanded
                            ? 'Hide full payload'
                            : 'Show full payload',
                        style: AppTextStyles.homeSubtitle.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_detailExpanded) ...[
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  entry.detail!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _tagColor(String tag) {
    return switch (tag) {
      'START' => const Color(0xFF1565C0),
      'DONE' => AppColors.safeGreen,
      'WARN' => AppColors.suspiciousOrange,
      'FAIL' => AppColors.dangerousRed,
      _ => AppColors.textMuted,
    };
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
