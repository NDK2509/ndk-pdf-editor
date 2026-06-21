import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_editor/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfEditorApp());
    expect(find.byType(PdfEditorApp), findsOneWidget);
  });
}
