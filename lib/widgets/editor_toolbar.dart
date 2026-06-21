import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../models/pdf_annotation.dart';
import '../providers/editor_provider.dart';

/// The top toolbar with file, view, and tool controls.
class EditorToolbar extends StatefulWidget {
  final EditorProvider provider;
  final VoidCallback onOpenFile;
  final VoidCallback onSaveFile;
  final VoidCallback onPrint;

  const EditorToolbar({
    super.key,
    required this.provider,
    required this.onOpenFile,
    required this.onSaveFile,
    required this.onPrint,
  });

  @override
  State<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollArrows();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollArrows);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollArrows() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    final showLeft = currentScroll > 5;
    final showRight = currentScroll < maxScroll - 5 && maxScroll > 0;

    if (showLeft != _showLeftArrow || showRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = showLeft;
        _showRightArrow = showRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final state = widget.provider.state;
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.surfaceMid,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.textMuted.withValues(alpha: 0.15),
              ),
            ),
            boxShadow: AppTheme.elevation1,
          ),
          child: Row(
            children: [
              const SizedBox(width: AppTheme.spacingSm),
              // Left: Logo
              _buildLogo(),
              const SizedBox(width: AppTheme.spacingMd),
              _divider(),
              // Middle: Scrollable controls to prevent overflow
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        _updateScrollArrows();
                        return false;
                      },
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            final newOffset = (_scrollController.offset + pointerSignal.scrollDelta.dy).clamp(
                              0.0,
                              _scrollController.position.maxScrollExtent,
                            );
                            _scrollController.jumpTo(newOffset);
                          }
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // File actions
                              _toolbarButton(
                                icon: Icons.folder_open_rounded,
                                tooltip: 'Open PDF (Ctrl+O)',
                                onPressed: widget.onOpenFile,
                              ),
                              _toolbarButton(
                                icon: Icons.save_rounded,
                                tooltip: 'Save (Ctrl+S)',
                                onPressed: state.filePath != null ? widget.onSaveFile : null,
                              ),
                              _toolbarButton(
                                icon: Icons.print_rounded,
                                tooltip: 'Print (Ctrl+P)',
                                onPressed: state.filePath != null ? widget.onPrint : null,
                              ),
                              _divider(),
                              // Undo / Redo
                              _toolbarButton(
                                icon: Icons.undo_rounded,
                                tooltip: 'Undo (Ctrl+Z)',
                                onPressed: state.undoStack.isNotEmpty
                                    ? () => widget.provider.undo()
                                    : null,
                              ),
                              _toolbarButton(
                                icon: Icons.redo_rounded,
                                tooltip: 'Redo (Ctrl+Y)',
                                onPressed: state.redoStack.isNotEmpty
                                    ? () => widget.provider.redo()
                                    : null,
                              ),
                              _divider(),
                              // Drawing tools
                              _toolToggle(
                                icon: Icons.pan_tool_rounded,
                                tooltip: 'Select & Navigate',
                                tool: AnnotationType.select,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.select),
                              ),
                              _toolToggle(
                                icon: Icons.gesture_rounded,
                                tooltip: 'Freehand Draw',
                                tool: AnnotationType.freehand,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.freehand),
                              ),
                              _toolToggle(
                                icon: Icons.text_fields_rounded,
                                tooltip: 'Add Text',
                                tool: AnnotationType.text,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.text),
                              ),
                              _toolToggle(
                                icon: Icons.highlight_rounded,
                                tooltip: 'Highlight',
                                tool: AnnotationType.highlight,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.highlight),
                              ),
                              _toolToggle(
                                icon: Icons.rectangle_outlined,
                                tooltip: 'Rectangle',
                                tool: AnnotationType.rectangle,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.rectangle),
                              ),
                              _toolToggle(
                                icon: Icons.circle_outlined,
                                tooltip: 'Circle',
                                tool: AnnotationType.circle,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.circle),
                              ),
                              _toolToggle(
                                icon: Icons.arrow_forward_rounded,
                                tooltip: 'Arrow',
                                tool: AnnotationType.arrow,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.arrow),
                              ),
                              _toolToggle(
                                icon: Icons.auto_fix_high_rounded,
                                tooltip: 'Eraser',
                                tool: AnnotationType.eraser,
                                currentTool: state.currentTool,
                                onPressed: () => widget.provider.setTool(AnnotationType.eraser),
                              ),
                              _divider(),
                              // Colors
                              ...AppTheme.annotationColors.take(6).map((c) => _colorChip(
                                    color: c,
                                    isSelected: state.currentColor == c,
                                    onTap: () => widget.provider.setColor(c),
                                  )),
                              _moreColorsButton(context),
                              _divider(),
                              // Stroke width
                              SizedBox(
                                width: 100,
                                child: Row(
                                  children: [
                                    const Icon(Icons.line_weight_rounded,
                                        size: 16, color: AppTheme.textSecondary),
                                    Expanded(
                                      child: Slider(
                                        value: state.currentStrokeWidth,
                                        min: 1,
                                        max: 12,
                                        divisions: 11,
                                        activeColor: AppTheme.primary,
                                        inactiveColor: AppTheme.textMuted.withValues(alpha: 0.3),
                                        onChanged: (v) => widget.provider.setStrokeWidth(v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Left arrow fade indicator
                    if (_showLeftArrow)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.surfaceMid,
                                AppTheme.surfaceMid.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppTheme.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _scrollController.animateTo(
                                  (_scrollController.offset - 120).clamp(0, _scrollController.position.maxScrollExtent),
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    // Right arrow fade indicator
                    if (_showRightArrow)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.surfaceMid.withValues(alpha: 0.0),
                                AppTheme.surfaceMid,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _scrollController.animateTo(
                                  (_scrollController.offset + 120).clamp(0, _scrollController.position.maxScrollExtent),
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _divider(),
              // Right: Zoom controls, Study Mode Switch, Sidebars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toolbarButton(
                    icon: Icons.zoom_out_rounded,
                    tooltip: 'Zoom Out',
                    onPressed: state.filePath != null
                        ? () => widget.provider.zoomOut()
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${(state.zoom * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _toolbarButton(
                    icon: Icons.zoom_in_rounded,
                    tooltip: 'Zoom In',
                    onPressed: state.filePath != null
                        ? () => widget.provider.zoomIn()
                        : null,
                  ),
                  _divider(),
                  // Study Mode Switch
                  Row(
                    children: [
                      Icon(
                        state.isStudyModeEnabled
                            ? Icons.school
                            : Icons.school_outlined,
                        size: 17,
                        color: state.isStudyModeEnabled
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Study Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: state.isStudyModeEnabled,
                          activeThumbColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                          inactiveThumbColor: AppTheme.textSecondary,
                          inactiveTrackColor: AppTheme.surfaceCard,
                          onChanged: state.filePath != null
                              ? (_) => widget.provider.toggleStudyMode()
                              : null,
                        ),
                      ),
                    ],
                  ),
                  _divider(),
                  // Sidebar toggle
                  _toolbarButton(
                    icon: state.isSidebarOpen
                        ? Icons.view_sidebar_rounded
                        : Icons.view_sidebar_outlined,
                    tooltip: 'Toggle Sidebar',
                    onPressed: () => widget.provider.toggleSidebar(),
                  ),
                  _toolbarButton(
                    icon: state.isNotesSidebarOpen
                        ? Icons.note_alt_rounded
                        : Icons.note_alt_outlined,
                    tooltip: 'Toggle Notes Sidebar',
                    onPressed: () => widget.provider.toggleNotesSidebar(),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacingSm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.glowPrimary,
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'NDK PDF Editor',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.textMuted.withValues(alpha: 0.2),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onPressed,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 19,
              color: onPressed != null
                  ? AppTheme.textSecondary
                  : AppTheme.textMuted.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolToggle({
    required IconData icon,
    required String tooltip,
    required AnnotationType tool,
    required AnnotationType currentTool,
    required VoidCallback onPressed,
  }) {
    final isActive = tool == currentTool;
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: isActive
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            onTap: onPressed,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 19,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorChip({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        width: 22,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: isSelected ? AppTheme.glowPrimary : null,
        ),
      ),
    );
  }

  Widget _moreColorsButton(BuildContext context) {
    return Tooltip(
      message: 'More colors',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () async {
            // Show a color picker dialog
            final colors = AppTheme.annotationColors;
            final selected = await showDialog<Color>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.surfaceCard,
                title: const Text('Pick a color'),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors
                      .map((c) => GestureDetector(
                            onTap: () => Navigator.pop(ctx, c),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            );
            if (selected != null) {
              widget.provider.setColor(selected);
            }
          },
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }
}
