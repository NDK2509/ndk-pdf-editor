import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/editor_provider.dart';

class NotesSidebar extends StatefulWidget {
  final EditorProvider provider;

  const NotesSidebar({super.key, required this.provider});

  @override
  State<NotesSidebar> createState() => _NotesSidebarState();
}

class _NotesSidebarState extends State<NotesSidebar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.state.personalNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final state = widget.provider.state;
        if (!state.isNotesSidebarOpen) {
          return const SizedBox.shrink();
        }

        // Keep local controller in sync if state is cleared/updated externally
        if (_controller.text != state.personalNotes) {
          _controller.text = state.personalNotes;
        }

        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppTheme.surfaceMid,
            border: Border(
              left: BorderSide(
                color: AppTheme.textMuted.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textMuted.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'WORKSPACE NOTES',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: AppTheme.textSecondary,
                      onPressed: () => widget.provider.toggleNotesSidebar(),
                    ),
                  ],
                ),
              ),
              // Note editor
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    cursorColor: AppTheme.primary,
                    decoration: InputDecoration(
                      hintText: 'Start writing notes here...',
                      hintStyle: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (text) => widget.provider.setPersonalNotes(text),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
