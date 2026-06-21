import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/editor_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfEditorApp());
}

class PdfEditorApp extends StatelessWidget {
  const PdfEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const EditorPage(),
    );
  }
}
