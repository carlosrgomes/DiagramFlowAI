import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';

void main() {
  testWidgets('DiagramCanvas renders InteractiveViewer and CustomPaint', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiagramCanvas(),
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
