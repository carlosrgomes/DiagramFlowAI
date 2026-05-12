import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/diagram_exporter.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/diagram_viewport.dart';
import 'package:diagram_flow_ai/models/gallery_controller.dart';
import 'package:diagram_flow_ai/models/mermaid_validator.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:diagram_flow_ai/models/prompt_dispatcher.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/app_shell.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterGemma.initialize();
  } catch (e, st) {
    debugPrint('[FlutterGemma] initialize() failed: $e\n$st');
  }
  await AssetManager.loadCatalog();

  final themeController = ThemeController();
  await themeController.load();

  final recentFiles = RecentFiles();
  await recentFiles.load();

  final aiState = AIModelState();
  await aiState.refreshInstalledStatus();
  await aiState.tryRestoreFromCache();
  // Fallback: if cache restore didn't load (e.g., first launch on this
  // machine but model file is on disk), auto-load any installed model so
  // the user doesn't need to click.
  unawaited(aiState.autoLoadIfInstalled());

  runApp(DiagramFlowApp(
    aiState: aiState,
    recentFiles: recentFiles,
    themeController: themeController,
  ));
}

class DiagramFlowApp extends StatelessWidget {
  final AIModelState aiState;
  final RecentFiles recentFiles;
  final ThemeController themeController;
  const DiagramFlowApp({
    super.key,
    required this.aiState,
    required this.recentFiles,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiagramState()),
        ChangeNotifierProvider.value(value: aiState),
        Provider(create: (_) => DiagramExporter()),
        Provider(create: (_) => MermaidValidator()),
        ChangeNotifierProvider(create: (_) => DiagramViewport()),
        ChangeNotifierProvider(create: (_) => GalleryController()),
        ChangeNotifierProvider.value(value: recentFiles),
        ChangeNotifierProvider.value(value: themeController),
        Provider(create: (_) => PromptDispatcher(), dispose: (_, d) => d.dispose()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Diagram Flow AI',
          theme: ThemeData(
            brightness: theme.isDark ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
              seedColor: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              secondary: AppColors.secondary,
              onSecondary: AppColors.onSecondary,
              error: AppColors.error,
            ),
            scaffoldBackgroundColor: AppColors.background,
            textTheme: TextTheme(
              displayLarge: AppTypography.display,
              headlineLarge: AppTypography.h1,
              headlineMedium: AppTypography.h2,
              bodyLarge: AppTypography.bodyLg,
              bodyMedium: AppTypography.bodyMd,
              labelLarge: AppTypography.labelCaps,
            ),
            useMaterial3: true,
          ),
          home: const AppShell(),
        ),
      ),
    );
  }
}
