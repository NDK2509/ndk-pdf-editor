import 'dart:ui';
import 'pdf_annotation.dart';

/// Represents the full state of the PDF editor.
class EditorState {
  final String? filePath;
  final String? fileName;
  final int currentPage;
  final int totalPages;
  final double zoom;
  final AnnotationType currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final double currentFontSize;
  final Map<int, List<PdfAnnotation>> annotations; // pageIndex -> annotations
  final List<EditorAction> undoStack;
  final List<EditorAction> redoStack;
  final bool isSidebarOpen;
  final bool isNotesSidebarOpen;
  final bool isStudyModeEnabled;
  final String personalNotes;
  final bool isModified;

  const EditorState({
    this.filePath,
    this.fileName,
    this.currentPage = 0,
    this.totalPages = 0,
    this.zoom = 1.0,
    this.currentTool = AnnotationType.select,
    this.currentColor = const Color(0xFFFF5252),
    this.currentStrokeWidth = 3.0,
    this.currentFontSize = 16.0,
    this.annotations = const {},
    this.undoStack = const [],
    this.redoStack = const [],
    this.isSidebarOpen = true,
    this.isNotesSidebarOpen = false,
    this.isStudyModeEnabled = false,
    this.personalNotes = '',
    this.isModified = false,
  });

  EditorState copyWith({
    String? filePath,
    String? fileName,
    int? currentPage,
    int? totalPages,
    double? zoom,
    AnnotationType? currentTool,
    Color? currentColor,
    double? currentStrokeWidth,
    double? currentFontSize,
    Map<int, List<PdfAnnotation>>? annotations,
    List<EditorAction>? undoStack,
    List<EditorAction>? redoStack,
    bool? isSidebarOpen,
    bool? isNotesSidebarOpen,
    bool? isStudyModeEnabled,
    String? personalNotes,
    bool? isModified,
  }) {
    return EditorState(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoom: zoom ?? this.zoom,
      currentTool: currentTool ?? this.currentTool,
      currentColor: currentColor ?? this.currentColor,
      currentStrokeWidth: currentStrokeWidth ?? this.currentStrokeWidth,
      currentFontSize: currentFontSize ?? this.currentFontSize,
      annotations: annotations ?? this.annotations,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      isNotesSidebarOpen: isNotesSidebarOpen ?? this.isNotesSidebarOpen,
      isStudyModeEnabled: isStudyModeEnabled ?? this.isStudyModeEnabled,
      personalNotes: personalNotes ?? this.personalNotes,
      isModified: isModified ?? this.isModified,
    );
  }

  /// Get annotations for a specific page.
  List<PdfAnnotation> getPageAnnotations(int pageIndex) {
    return annotations[pageIndex] ?? [];
  }
}

/// Represents a reversible editor action for undo/redo.
class EditorAction {
  final String type; // 'add', 'remove', 'modify'
  final PdfAnnotation annotation;
  final PdfAnnotation? previousState;

  const EditorAction({
    required this.type,
    required this.annotation,
    this.previousState,
  });
}
