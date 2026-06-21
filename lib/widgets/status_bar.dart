import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/editor_provider.dart';

/// Bottom status bar showing file info, page, and zoom.
class StatusBar extends StatelessWidget {
  final EditorProvider provider;

  const StatusBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final state = provider.state;
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMid,
            border: Border(
              top: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.15)),
            ),
          ),
          child: Row(
            children: [
              if (state.fileName != null) ...[
                Icon(Icons.description_rounded, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  state.fileName!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                if (state.isModified)
                  const Text(' •', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
              ],
              const Spacer(),
              if (state.filePath != null) ...[
                // Page navigation
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  onPressed: state.currentPage > 0 ? () => provider.previousPage() : null,
                  color: AppTheme.textSecondary,
                  disabledColor: AppTheme.textMuted.withValues(alpha: 0.3),
                ),
                Text(
                  'Page ${state.currentPage + 1} of ${state.totalPages}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  onPressed: state.currentPage < state.totalPages - 1 ? () => provider.nextPage() : null,
                  color: AppTheme.textSecondary,
                  disabledColor: AppTheme.textMuted.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 16),
                Text(
                  'Zoom: ${(state.zoom * 100).round()}%',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(width: 16),
                Text(
                  'Tool: ${state.currentTool.name}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ] else
                const Text(
                  'Ready',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }
}
