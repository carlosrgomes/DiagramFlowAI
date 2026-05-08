import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/top_nav_bar.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';

void main() {
  testWidgets('TopNavBar renders branding, links, and tool palette', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          textTheme: TextTheme(
            headlineMedium: AppTypography.h2,
            bodyMedium: AppTypography.bodyMd,
          ),
        ),
        home: const Scaffold(
          body: TopNavBar(),
        ),
      ),
    );

    // Branding
    expect(find.text('CloudFlow AI'), findsOneWidget);

    // Links
    expect(find.text('Canvas'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Deployment'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Tool Palette Icons
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    expect(find.byIcon(Icons.near_me_outlined), findsOneWidget);
    
    // User Actions
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
