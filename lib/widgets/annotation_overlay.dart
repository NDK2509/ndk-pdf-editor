import 'package:flutter/material.dart';
import '../models/pdf_annotation.dart';
import '../models/editor_state.dart';
import '../providers/editor_provider.dart';
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

  String _generateId() => 'ann_${widget.pageIndex}_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final state = widget.provider.state;
        final annotations = state.getPageAnnotations(widget.pageIndex);
        final tool = state.currentTool;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: tool == AnnotationType.text ? (details) => _handleTextTap(details, state) : null,
          onPanStart: tool != AnnotationType.text ? (details) => _handlePanStart(details, state) : null,
          onPanUpdate: tool != AnnotationType.text ? (details) => _handlePanUpdate(details, state) : null,
          onPanEnd: tool != AnnotationType.text ? (details) => _handlePanEnd(state) : null,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: AnnotationPainter(
                annotations: annotations,
                currentAnnotation: _currentAnnotation,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  void _handlePanStart(DragStartDetails details, EditorState state) {
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

  void _handleTextTap(TapUpDetails details, EditorState state) async {
    final pos = details.localPosition;
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2746),
        title: const Text('Add Text Annotation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      widget.provider.addAnnotation(PdfAnnotation(
        id: _generateId(),
        pageIndex: widget.pageIndex,
        type: AnnotationType.text,
        points: [pos],
        color: state.currentColor,
        strokeWidth: state.currentStrokeWidth,
        text: text,
        fontSize: state.currentFontSize,
      ));
    }
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
