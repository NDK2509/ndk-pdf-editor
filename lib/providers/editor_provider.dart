import 'package:flutter/material.dart';
import '../models/pdf_annotation.dart';
import '../models/editor_state.dart';

/// Provider that manages the PDF editor state.
class EditorProvider extends ChangeNotifier {
  EditorState _state = const EditorState();

  EditorState get state => _state;

  // ─── File operations ───

  void setFile(String path, String name) {
    _state = _state.copyWith(
      filePath: path,
      fileName: name,
      currentPage: 0,
      annotations: {},
      undoStack: [],
      redoStack: [],
      isModified: false,
    );
    notifyListeners();
  }

  void setTotalPages(int count) {
    _state = _state.copyWith(totalPages: count);
    notifyListeners();
  }

  void closeFile() {
    _state = const EditorState();
    notifyListeners();
  }

  // ─── Navigation ───

  void setCurrentPage(int page) {
    if (page >= 0 && page < _state.totalPages) {
      _state = _state.copyWith(currentPage: page);
      notifyListeners();
    }
  }

  void nextPage() => setCurrentPage(_state.currentPage + 1);
  void previousPage() => setCurrentPage(_state.currentPage - 1);

  // ─── Zoom ───

  void setZoom(double zoom) {
    _state = _state.copyWith(zoom: zoom.clamp(0.25, 5.0));
    notifyListeners();
  }

  void zoomIn() => setZoom(_state.zoom + 0.25);
  void zoomOut() => setZoom(_state.zoom - 0.25);
  void resetZoom() => setZoom(1.0);

  // ─── Tools ───

  void setTool(AnnotationType tool) {
    _state = _state.copyWith(currentTool: tool);
    notifyListeners();
  }

  void setColor(Color color) {
    _state = _state.copyWith(currentColor: color);
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _state = _state.copyWith(currentStrokeWidth: width);
    notifyListeners();
  }

  void setFontSize(double size) {
    _state = _state.copyWith(currentFontSize: size);
    notifyListeners();
  }

  // ─── Annotations ───

  void addAnnotation(PdfAnnotation annotation) {
    final pageAnnotations =
        Map<int, List<PdfAnnotation>>.from(_state.annotations);
    final list = List<PdfAnnotation>.from(
      pageAnnotations[annotation.pageIndex] ?? [],
    );
    list.add(annotation);
    pageAnnotations[annotation.pageIndex] = list;

    final undoStack = List<EditorAction>.from(_state.undoStack);
    undoStack.add(EditorAction(type: 'add', annotation: annotation));

    _state = _state.copyWith(
      annotations: pageAnnotations,
      undoStack: undoStack,
      redoStack: [],
      isModified: true,
    );
    notifyListeners();
  }

  void removeAnnotation(String id, int pageIndex) {
    final pageAnnotations =
        Map<int, List<PdfAnnotation>>.from(_state.annotations);
    final list = List<PdfAnnotation>.from(
      pageAnnotations[pageIndex] ?? [],
    );
    final idx = list.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final removed = list.removeAt(idx);
      pageAnnotations[pageIndex] = list;

      final undoStack = List<EditorAction>.from(_state.undoStack);
      undoStack.add(EditorAction(type: 'remove', annotation: removed));

      _state = _state.copyWith(
        annotations: pageAnnotations,
        undoStack: undoStack,
        redoStack: [],
        isModified: true,
      );
      notifyListeners();
    }
  }

  void clearPageAnnotations(int pageIndex) {
    final pageAnnotations =
        Map<int, List<PdfAnnotation>>.from(_state.annotations);
    pageAnnotations[pageIndex] = [];
    _state = _state.copyWith(
      annotations: pageAnnotations,
      isModified: true,
    );
    notifyListeners();
  }

  void clearAllAnnotations() {
    _state = _state.copyWith(
      annotations: {},
      undoStack: [],
      redoStack: [],
      isModified: true,
    );
    notifyListeners();
  }

  // ─── Undo / Redo ───

  void undo() {
    if (_state.undoStack.isEmpty) return;

    final undoStack = List<EditorAction>.from(_state.undoStack);
    final action = undoStack.removeLast();
    final redoStack = List<EditorAction>.from(_state.redoStack);
    redoStack.add(action);

    final pageAnnotations =
        Map<int, List<PdfAnnotation>>.from(_state.annotations);

    if (action.type == 'add') {
      // Undo add: remove the annotation
      final list = List<PdfAnnotation>.from(
        pageAnnotations[action.annotation.pageIndex] ?? [],
      );
      list.removeWhere((a) => a.id == action.annotation.id);
      pageAnnotations[action.annotation.pageIndex] = list;
    } else if (action.type == 'remove') {
      // Undo remove: add it back
      final list = List<PdfAnnotation>.from(
        pageAnnotations[action.annotation.pageIndex] ?? [],
      );
      list.add(action.annotation);
      pageAnnotations[action.annotation.pageIndex] = list;
    }

    _state = _state.copyWith(
      annotations: pageAnnotations,
      undoStack: undoStack,
      redoStack: redoStack,
      isModified: true,
    );
    notifyListeners();
  }

  void redo() {
    if (_state.redoStack.isEmpty) return;

    final redoStack = List<EditorAction>.from(_state.redoStack);
    final action = redoStack.removeLast();
    final undoStack = List<EditorAction>.from(_state.undoStack);
    undoStack.add(action);

    final pageAnnotations =
        Map<int, List<PdfAnnotation>>.from(_state.annotations);

    if (action.type == 'add') {
      // Redo add: add it back
      final list = List<PdfAnnotation>.from(
        pageAnnotations[action.annotation.pageIndex] ?? [],
      );
      list.add(action.annotation);
      pageAnnotations[action.annotation.pageIndex] = list;
    } else if (action.type == 'remove') {
      // Redo remove: remove it
      final list = List<PdfAnnotation>.from(
        pageAnnotations[action.annotation.pageIndex] ?? [],
      );
      list.removeWhere((a) => a.id == action.annotation.id);
      pageAnnotations[action.annotation.pageIndex] = list;
    }

    _state = _state.copyWith(
      annotations: pageAnnotations,
      undoStack: undoStack,
      redoStack: redoStack,
      isModified: true,
    );
    notifyListeners();
  }

  // ─── Sidebar ───

  void toggleSidebar() {
    _state = _state.copyWith(isSidebarOpen: !_state.isSidebarOpen);
    notifyListeners();
  }

  void toggleNotesSidebar() {
    _state = _state.copyWith(isNotesSidebarOpen: !_state.isNotesSidebarOpen);
    notifyListeners();
  }

  void setPersonalNotes(String notes) {
    _state = _state.copyWith(personalNotes: notes);
    notifyListeners();
  }
}
