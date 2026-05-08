import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/resource_sidebar.dart';

void main() {
  testWidgets('ResourceSidebar renders categories and items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResourceSidebar(),
        ),
      ),
    );

    expect(find.text('Resource Library'), findsOneWidget);
    expect(find.text('Compute'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('EC2 Instance'), findsOneWidget);
    expect(find.text('S3 Bucket'), findsOneWidget);
    expect(find.byType(Draggable<ResourceTemplate>), findsWidgets);
  });
}
