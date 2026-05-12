import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/diagram_viewport.dart';
import 'package:diagram_flow_ai/models/gallery_controller.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/top_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('TopNavBar renders branding, file menu, undo/redo and tool palette',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DiagramState()),
          ChangeNotifierProvider(create: (_) => DiagramViewport()),
          ChangeNotifierProvider(create: (_) => GalleryController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => RecentFiles()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            textTheme: TextTheme(
              headlineMedium: AppTypography.h2,
              bodyMedium: AppTypography.bodyMd,
            ),
          ),
          home: Scaffold(
            body: TopNavBar(
              onNew: () {},
              onOpen: () {},
              onSave: () {},
              onSaveAs: () {},
              onOpenRecent: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Diagram Flow AI'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.redo), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    expect(find.byIcon(Icons.pan_tool_outlined), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
