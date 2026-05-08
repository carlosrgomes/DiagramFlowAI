import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
    return const Scaffold(
      body: Center(
        child: Text('DiagramFlow AI Initialized'),
      ),
    );
  }
}
