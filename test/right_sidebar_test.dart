import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/mermaid_validator.dart';
import 'package:diagram_flow_ai/models/prompt_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/right_sidebar.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('RightSidebar renders Mermaid code panel and AI chat sections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DiagramState()),
          ChangeNotifierProvider(create: (_) => AIModelState()),
          Provider(create: (_) => PromptDispatcher(), dispose: (_, d) => d.dispose()),
          Provider(create: (_) => MermaidValidator()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            textTheme: TextTheme(
              labelLarge: AppTypography.labelCaps,
              bodyMedium: AppTypography.bodyMd,
            ),
          ),
          home: const Scaffold(
            body: RightSidebar(),
          ),
        ),
      ),
    );

    expect(find.text('ASSISTANT'), findsOneWidget);
    expect(find.text('SYSTEM LOGS'), findsOneWidget);

    // Code editor + chat input — at least two TextFields
    expect(find.byType(TextField), findsAtLeastNWidgets(2));

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
