import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../providers/editor_provider.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/page_thumbnail_sidebar.dart';
import '../widgets/annotation_overlay.dart';
import '../widgets/welcome_screen.dart';
import '../widgets/status_bar.dart';
import '../widgets/notes_sidebar.dart';
import '../widgets/study_timer.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final EditorProvider _provider = EditorProvider();
  String? _currentFilePath;
  PdfDocument? _thumbnailDocument;
  final PdfViewerController _viewerController = PdfViewerController();

  Future<void> _openFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'Open PDF File',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      try {
        // Load document for thumbnail sidebar
        final doc = await PdfDocument.openFile(path);
        setState(() {
          _currentFilePath = path;
          _thumbnailDocument = doc;
        });
        _provider.setFile(path, name);
        _provider.setTotalPages(doc.pages.length);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open PDF: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveFile() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annotations saved in session. Use Print to export.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _printFile() async {
    if (_provider.state.filePath == null) return;
    try {
      final bytes = await File(_provider.state.filePath!).readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyO, control: true): _openFile,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveFile,
          const SingleActivator(LogicalKeyboardKey.keyP, control: true): _printFile,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _provider.undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): _provider.redo,
          const SingleActivator(LogicalKeyboardKey.equal, control: true): _provider.zoomIn,
          const SingleActivator(LogicalKeyboardKey.minus, control: true): _provider.zoomOut,
          const SingleActivator(LogicalKeyboardKey.digit0, control: true): _provider.resetZoom,
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              EditorToolbar(
                provider: _provider,
                onOpenFile: _openFile,
                onSaveFile: _saveFile,
                onPrint: _printFile,
              ),
              Expanded(
                child: Row(
                  children: [
                    PageThumbnailSidebar(
                      provider: _provider,
                      document: _thumbnailDocument,
                    ),
                    Expanded(child: _buildMainArea()),
                    NotesSidebar(provider: _provider),
                  ],
                ),
              ),
              StatusBar(provider: _provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        if (_currentFilePath == null) {
          return WelcomeScreen(onOpenFile: _openFile);
        }
        final state = _provider.state;
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                child: _buildPdfViewer(),
              ),
            ),
            if (state.isStudyModeEnabled)
              const Positioned(
                top: 16,
                right: 16,
                child: StudyTimerWidget(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPdfViewer() {
    if (_currentFilePath == null) return const SizedBox.shrink();

    return PdfViewer.file(
      _currentFilePath!,
      controller: _viewerController,
      params: PdfViewerParams(
        backgroundColor: AppTheme.surfaceDark,
        scrollByMouseWheel: 1.0,
        pageOverlaysBuilder: (context, pageRect, page) {
          return [
            AnnotationOverlay(
              provider: _provider,
              pageIndex: page.pageNumber - 1,
            ),
          ];
        },
        viewerOverlayBuilder: (context, size, handleLinkTap) => [],
        onPageChanged: (page) {
          if (page != null) {
            _provider.setCurrentPage(page - 1);
          }
        },
      ),
    );
  }
}
