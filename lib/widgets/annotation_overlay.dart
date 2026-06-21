import 'package:flutter/material.dart';
import '../models/pdf_annotation.dart';
import '../models/editor_state.dart';
import '../providers/editor_provider.dart';
import '../theme/app_theme.dart';
import 'annotation_painter.dart';

/// Overlay widget that captures drawing gestures and renders annotations on a PDF page.
class AnnotationOverlay extends StatefulWidget {
  final EditorProvider provider;
  final int pageIndex;

  const AnnotationOverlay({
    super.key,
    required this.provider,
    required this.pageIndex,
  });

  @override
  State<AnnotationOverlay> createState() => _AnnotationOverlayState();
}

class _AnnotationOverlayState extends State<AnnotationOverlay> {
  PdfAnnotation? _currentAnnotation;
  List<Offset> _currentPoints = [];
  int _idCounter = 0;

  Offset? _editingTextPosition;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  String _generateId() => 'ann_${widget.pageIndex}_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  @override
  void initState() {
    super.initState();
    _textFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _textFocusNode.removeListener(_onFocusChange);
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_textFocusNode.hasFocus && _editingTextPosition != null) {
      _submitText(widget.provider.state);
    }
  }

  void _submitText(EditorState state) {
    final text = _textController.text.trim();
    if (text.isNotEmpty && _editingTextPosition != null) {
      widget.provider.addAnnotation(PdfAnnotation(
        id: _generateId(),
        pageIndex: widget.pageIndex,
        type: AnnotationType.text,
        points: [_editingTextPosition!],
        color: state.currentColor,
        strokeWidth: state.currentStrokeWidth,
        text: text,
        fontSize: state.currentFontSize,
      ));
    }
    setState(() {
      _editingTextPosition = null;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final state = widget.provider.state;
        final annotations = state.getPageAnnotations(widget.pageIndex);
        final tool = state.currentTool;

        final isDrawingTool = tool == AnnotationType.freehand ||
            tool == AnnotationType.highlight ||
            tool == AnnotationType.rectangle ||
            tool == AnnotationType.circle ||
            tool == AnnotationType.arrow ||
            tool == AnnotationType.eraser;

        final showOverlayInput = _editingTextPosition != null;

        Widget content = RepaintBoundary(
          child: CustomPaint(
            painter: AnnotationPainter(
              annotations: annotations,
              currentAnnotation: _currentAnnotation,
            ),
            size: Size.infinite,
          ),
        );

        if (tool != AnnotationType.select || showOverlayInput) {
          content = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: tool == AnnotationType.text ? (details) => _handleTextTap(details, state) : null,
            onPanStart: isDrawingTool ? (details) => _handlePanStart(details, state) : null,
            onPanUpdate: isDrawingTool ? (details) => _handlePanUpdate(details, state) : null,
            onPanEnd: isDrawingTool ? (details) => _handlePanEnd(state) : null,
            child: content,
          );
        }

        return IgnorePointer(
          ignoring: tool == AnnotationType.select && !showOverlayInput,
          child: Stack(
            children: [
              Positioned.fill(child: content),
              if (showOverlayInput)
                Positioned(
                  left: _editingTextPosition!.dx,
                  top: _editingTextPosition!.dy - 16,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: AppTheme.elevation2,
                      border: Border.all(color: AppTheme.primary, width: 1.5),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      autofocus: true,
                      maxLines: 1,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type note...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _submitText(state),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handlePanStart(DragStartDetails details, EditorState state) {
    if (_editingTextPosition != null) {
      _submitText(state);
    }
    
    final pos = details.localPosition;
    _currentPoints = [pos];

    if (state.currentTool == AnnotationType.eraser) {
      _tryErase(pos);
      return;
    }

    _currentAnnotation = PdfAnnotation(
      id: _generateId(),
      pageIndex: widget.pageIndex,
      type: state.currentTool,
      points: _currentPoints,
      color: state.currentColor,
      strokeWidth: state.currentStrokeWidth,
    );
    setState(() {});
  }

  void _handlePanUpdate(DragUpdateDetails details, EditorState state) {
    final pos = details.localPosition;

    if (state.currentTool == AnnotationType.eraser) {
      _tryErase(pos);
      return;
    }

    if (_currentAnnotation == null) return;

    if (state.currentTool == AnnotationType.freehand ||
        state.currentTool == AnnotationType.highlight) {
      _currentPoints = [..._currentPoints, pos];
    } else {
      // For shapes, keep start point and update end point
      _currentPoints = [_currentPoints.first, pos];
    }

    _currentAnnotation = _currentAnnotation!.copyWith(points: _currentPoints);
    setState(() {});
  }

  void _handlePanEnd(EditorState state) {
    if (state.currentTool == AnnotationType.eraser) return;
    if (_currentAnnotation == null) return;
    if (_currentPoints.length < 2) {
      _currentAnnotation = null;
      setState(() {});
      return;
    }

    widget.provider.addAnnotation(_currentAnnotation!);
    _currentAnnotation = null;
    _currentPoints = [];
    setState(() {});
  }

  void _handleTextTap(TapUpDetails details, EditorState state) {
    if (_editingTextPosition != null) {
      _submitText(state);
    }
    setState(() {
      _editingTextPosition = details.localPosition;
      _textController.clear();
    });
    _textFocusNode.requestFocus();
  }

  void _tryErase(Offset pos) {
    final annotations = widget.provider.state.getPageAnnotations(widget.pageIndex);
    for (final a in annotations.reversed) {
      for (final p in a.points) {
        if ((p - pos).distance < 20) {
          widget.provider.removeAnnotation(a.id, widget.pageIndex);
          return;
        }
      }
    }
  }
}
