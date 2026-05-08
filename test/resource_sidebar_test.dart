import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/resource_sidebar.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';

void main() {
  testWidgets('ResourceSidebar renders library sections and drag resources', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          textTheme: TextTheme(
            labelLarge: AppTypography.labelCaps,
            bodyMedium: AppTypography.bodyMd,
          ),
        ),
        home: const Scaffold(
          body: ResourceSidebar(),
        ),
      ),
    );

    // Section Headers
    expect(find.text('Cloud Library'), findsOneWidget);
    expect(find.text('DRAG RESOURCES'), findsOneWidget);
    expect(find.text('VPC-Primary-Alpha'), findsOneWidget);

    // Provider Tabs
    expect(find.text('AWS'), findsOneWidget);
    expect(find.text('Azure'), findsOneWidget);
    expect(find.text('GCP'), findsOneWidget);
    expect(find.text('Kubernetes'), findsOneWidget);

    // Specific Resource Buttons
    expect(find.text('EC2'), findsOneWidget);
    expect(find.text('RDS'), findsOneWidget);
    expect(find.text('S3'), findsOneWidget);
    expect(find.text('VPC'), findsOneWidget);

    // Action Button
    expect(find.text('+ Add Resource'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
