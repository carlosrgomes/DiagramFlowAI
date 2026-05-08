import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/main.dart';

void main() {
  testWidgets('App initializes with welcome text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiagramFlowApp());

    // Verify that our welcome text is present.
    expect(find.text('Welcome to DiagramFlow AI'), findsOneWidget);
  });
}
