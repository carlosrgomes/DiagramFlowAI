import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/main.dart';

void main() {
  testWidgets('App initializes with DiagramCanvas', (WidgetTester tester) async {
    await tester.pumpWidget(DiagramFlowApp(
      aiState: AIModelState(),
      recentFiles: RecentFiles(),
      themeController: ThemeController(),
    ));

    expect(find.byType(DiagramCanvas), findsOneWidget);
  });
}
