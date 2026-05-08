import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/main.dart';

void main() {
  testWidgets('App initializes with DiagramCanvas', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiagramFlowApp());

    // Verify that our canvas is present.
    expect(find.byType(DiagramCanvas), findsOneWidget);
  });
}
