import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_exporter.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/diagram_viewport.dart';
import 'package:diagram_flow_ai/models/gallery_controller.dart';
import 'package:diagram_flow_ai/models/mermaid_validator.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:diagram_flow_ai/models/prompt_dispatcher.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/app_shell.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AppShell has Header, Footer, and 3-column body', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DiagramState()),
          ChangeNotifierProvider(create: (_) => AIModelState()),
          ChangeNotifierProvider(create: (_) => DiagramViewport()),
          ChangeNotifierProvider(create: (_) => GalleryController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => RecentFiles()),
          Provider(create: (_) => DiagramExporter()),
          Provider(create: (_) => MermaidValidator()),
          Provider(create: (_) => PromptDispatcher(), dispose: (_, d) => d.dispose()),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    // Verify presence of structural components
    expect(find.byType(DiagramCanvas), findsOneWidget);
    
    expect(find.text('ASSISTANT'), findsOneWidget);
    expect(find.text('Diagram Flow AI'), findsOneWidget);
    expect(find.textContaining('Gemma4 Connected'), findsOneWidget);

    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
