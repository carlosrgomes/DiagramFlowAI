import 'dart:math';
import 'package:flutter/material.dart';

class AICommand {
  final String label;
  final Offset position;

  AICommand({required this.label, required this.position});
}

class AIEngineService {
  AICommand? parsePrompt(String prompt) {
    final input = prompt.toLowerCase();
    
    String? resourceLabel;
    if (input.contains('ec2') || input.contains('instance')) {
      resourceLabel = 'EC2 Instance';
    } else if (input.contains('rds') || input.contains('database')) {
      resourceLabel = 'RDS Database';
    } else if (input.contains('s3') || input.contains('bucket')) {
      resourceLabel = 'S3 Bucket';
    } else if (input.contains('vpc') || input.contains('network')) {
      resourceLabel = 'VPC';
    } else if (input.contains('lambda') || input.contains('function')) {
      resourceLabel = 'Lambda Function';
    }

    if (resourceLabel != null) {
      // Random position for simulation
      final random = Random();
      return AICommand(
        label: resourceLabel,
        position: Offset(
          200.0 + random.nextDouble() * 400.0,
          200.0 + random.nextDouble() * 400.0,
        ),
      );
    }

    return null;
  }
}
