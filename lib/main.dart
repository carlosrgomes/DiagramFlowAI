import 'package:flutter/material.dart';

import 'package:diagram_flow_ai/models/asset_manager.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/theme/design_tokens.dart';
import 'package:diagram_flow_ai/widgets/app_shell.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AssetManager.loadCatalog();
  
  runApp(const DiagramFlowApp());
}

class DiagramFlowApp extends StatelessWidget {
  const DiagramFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiagramState()),
        ChangeNotifierProvider(create: (_) => AIModelState()),
      ],
      child: MaterialApp(
        title: 'DiagramFlow AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          error: AppColors.error,
        ),
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
    );
  }
}
