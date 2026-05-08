import 'package:flutter/material.dart';

import 'package:diagram_flow_ai/theme/design_tokens.dart';

import 'package:diagram_flow_ai/widgets/app_shell.dart';

void main() {
  runApp(const DiagramFlowApp());
}

class DiagramFlowApp extends StatelessWidget {
  const DiagramFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiagramFlow AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
        ),
        textTheme: const TextTheme(
          headlineMedium: AppTypography.headline,
          bodyMedium: AppTypography.body,
          labelLarge: AppTypography.label,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
