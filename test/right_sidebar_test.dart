import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/widgets/right_sidebar.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('RightSidebar renders Mermaid code and AI chat sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DiagramState()),
          ChangeNotifierProvider(create: (_) => AIModelState()),
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

    expect(find.text('Mermaid Architecture'), findsOneWidget);
    expect(find.text('Gemma4 AI Assistant'), findsOneWidget);
    
    // Check for some mock Mermaid code
    expect(find.textContaining('graph TD'), findsOneWidget);
    
    // Check for chat input
    expect(find.byType(TextField), findsOneWidget);
  });
}
