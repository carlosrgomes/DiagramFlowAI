import 'package:flutter/material.dart';

import 'package:diagram_flow_ai/theme/design_tokens.dart';

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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'DiagramFlow AI Initialized',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
