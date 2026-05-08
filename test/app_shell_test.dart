import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/app_shell.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:diagram_flow_ai/widgets/resource_sidebar.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AppShell has Header, Footer, and 3-column body', (WidgetTester tester) async {
    // Increase surface size to avoid overflow during tests
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DiagramState()),
          ChangeNotifierProvider(create: (_) => AIModelState()),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    // Verify presence of structural components
    expect(find.byType(ResourceSidebar), findsOneWidget);
    expect(find.byType(DiagramCanvas), findsOneWidget);
    
    expect(find.text('ASSISTANT'), findsOneWidget);
    expect(find.text('CloudFlow AI'), findsOneWidget);
    expect(find.textContaining('Gemma4 Connected'), findsOneWidget);

    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
