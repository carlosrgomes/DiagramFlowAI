import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/diagram_node.dart';

void main() {
  testWidgets('DiagramNodeWidget renders label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DiagramNodeWidget(
                label: 'Test Node',
                position: Offset(10, 10),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Test Node'), findsOneWidget);
  });
}
