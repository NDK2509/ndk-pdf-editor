import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/pdf_annotation.dart';

class AnnotationPainter extends CustomPainter {
  final List<PdfAnnotation> annotations;
  final PdfAnnotation? currentAnnotation;

  AnnotationPainter({required this.annotations, this.currentAnnotation});

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in annotations) {
      _paintAnnotation(canvas, a);
    }
    if (currentAnnotation != null) {
      _paintAnnotation(canvas, currentAnnotation!);
    }
  }

  void _paintAnnotation(Canvas canvas, PdfAnnotation a) {
    final paint = Paint()
      ..color = a.color
      ..strokeWidth = a.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (a.type) {
      case AnnotationType.freehand:
        if (a.points.length < 2) return;
        final path = Path()..moveTo(a.points[0].dx, a.points[0].dy);
        for (int i = 1; i < a.points.length; i++) {
          if (i < a.points.length - 1) {
            final mid = Offset(
              (a.points[i].dx + a.points[i + 1].dx) / 2,
              (a.points[i].dy + a.points[i + 1].dy) / 2,
            );
            path.quadraticBezierTo(a.points[i].dx, a.points[i].dy, mid.dx, mid.dy);
          } else {
            path.lineTo(a.points[i].dx, a.points[i].dy);
          }
        }
        canvas.drawPath(path, paint);
      case AnnotationType.highlight:
        if (a.points.length < 2) return;
        paint
          ..color = a.color.withValues(alpha: 0.35)
          ..strokeWidth = a.strokeWidth * 6
          ..strokeCap = StrokeCap.butt;
        final path = Path()..moveTo(a.points[0].dx, a.points[0].dy);
        for (int i = 1; i < a.points.length; i++) {
          path.lineTo(a.points[i].dx, a.points[i].dy);
        }
        canvas.drawPath(path, paint);
      case AnnotationType.rectangle:
        if (a.points.length < 2) return;
        final rect = Rect.fromPoints(a.points.first, a.points.last);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      case AnnotationType.circle:
        if (a.points.length < 2) return;
        canvas.drawOval(Rect.fromPoints(a.points.first, a.points.last), paint);
      case AnnotationType.arrow:
        if (a.points.length < 2) return;
        canvas.drawLine(a.points.first, a.points.last, paint);
        final angle = (a.points.last - a.points.first).direction;
        final p1 = a.points.last - Offset.fromDirection(angle - 0.5, 14);
        final p2 = a.points.last - Offset.fromDirection(angle + 0.5, 14);
        canvas.drawPath(
          Path()..moveTo(a.points.last.dx, a.points.last.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close(),
          paint..style = PaintingStyle.fill,
        );
      case AnnotationType.text:
        if (a.text == null || a.text!.isEmpty || a.points.isEmpty) return;
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: a.fontSize ?? 16));
        builder.pushStyle(ui.TextStyle(color: a.color));
        builder.addText(a.text!);
        final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 400));
        canvas.drawParagraph(paragraph, a.points.first);
      case AnnotationType.eraser:
      case AnnotationType.select:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) => true;
}
