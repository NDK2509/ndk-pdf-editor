import 'dart:ui';

/// Types of annotations supported by the PDF editor.
enum AnnotationType {
  select,
  freehand,
  text,
  highlight,
  rectangle,
  circle,
  arrow,
  eraser,
}

/// Represents a single annotation on a PDF page.
class PdfAnnotation {
  final String id;
  final int pageIndex;
  final AnnotationType type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String? text;
  final double? fontSize;
  final Rect? bounds;

  PdfAnnotation({
    required this.id,
    required this.pageIndex,
    required this.type,
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
    this.text,
    this.fontSize,
    this.bounds,
  });

  PdfAnnotation copyWith({
    String? id,
    int? pageIndex,
    AnnotationType? type,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    String? text,
    double? fontSize,
    Rect? bounds,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      bounds: bounds ?? this.bounds,
    );
  }
}
