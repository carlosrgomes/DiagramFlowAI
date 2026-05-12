import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/main.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('App uses Geist and JetBrains Mono fonts', (WidgetTester tester) async {
    // Disable HTTP requests for fonts during tests
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(DiagramFlowApp(
      aiState: AIModelState(),
      recentFiles: RecentFiles(),
      themeController: ThemeController(),
    ));

    // Verify Geist is applied to theme typography
    expect(AppTypography.h1.fontFamily, contains('Geist'));
    expect(AppTypography.bodyMd.fontFamily, contains('Geist'));
    
    // Verify JetBrains Mono is used for code snippets
    expect(AppTypography.code.fontFamily, contains('JetBrainsMono'));
  });
}
