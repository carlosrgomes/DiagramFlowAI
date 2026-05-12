import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('DiagramCanvas renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => DiagramState(),
            child: const DiagramCanvas(),
          ),
        ),
      ),
    );

    // WebView is present (WKWebView on macOS wraps inside a PlatformViewLink/UiKitView)
    expect(find.byType(DiagramCanvas), findsOneWidget);
  });
}
