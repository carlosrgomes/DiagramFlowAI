import 'dart:math';
import 'package:flutter/material.dart';

class AICommand {
  final String label;
  final Offset position;

  AICommand({required this.label, required this.position});
}

class AIEngineService {
  Stream<String> processPrompt(String prompt) async* {
    final input = prompt.toLowerCase();
    final random = Random();
    
    // Simulate initial thought
    yield 'THOUGHT: Analyzing request constraints and identifying resources...';
    await Future.delayed(const Duration(milliseconds: 800));
    
    List<AICommand> commands = [];
    
    if (input.contains('ec2') || input.contains('instance')) {
      yield 'THOUGHT: Identified Compute requirement. Planning EC2 placement.';
      await Future.delayed(const Duration(milliseconds: 600));
      commands.add(AICommand(
        label: 'EC2', 
        position: Offset(200.0 + random.nextDouble() * 100, 200.0 + random.nextDouble() * 100)
      ));
    }
    
    if (input.contains('s3') || input.contains('bucket')) {
      yield 'THOUGHT: Identified Storage requirement. Planning S3 Bucket placement.';
      await Future.delayed(const Duration(milliseconds: 600));
      commands.add(AICommand(
        label: 'S3', 
        position: Offset(400.0 + random.nextDouble() * 100, 200.0 + random.nextDouble() * 100)
      ));
    }

    if (input.contains('rds') || input.contains('database')) {
      yield 'THOUGHT: Identified Database requirement. Planning RDS placement.';
      await Future.delayed(const Duration(milliseconds: 600));
      commands.add(AICommand(
        label: 'RDS', 
        position: Offset(300.0 + random.nextDouble() * 100, 350.0 + random.nextDouble() * 100)
      ));
    }

    if (input.contains('vpc') || input.contains('network')) {
      yield 'THOUGHT: Identified Networking requirement. Planning VPC boundary.';
      await Future.delayed(const Duration(milliseconds: 600));
      commands.add(AICommand(
        label: 'VPC', 
        position: Offset(100.0 + random.nextDouble() * 50, 100.0 + random.nextDouble() * 50)
      ));
    }
    
    if (input.contains('chamando') || input.contains('connect') || input.contains('call') || input.contains('->')) {
       yield 'THOUGHT: Interpreting connection semantics between resources. (Note: Lines will be implemented in a future track).';
       await Future.delayed(const Duration(milliseconds: 600));
    }
    
    if (commands.isNotEmpty) {
      // Serialize commands to be parsed by the UI
      final cmdsString = commands.map((c) => "${c.label}@${c.position.dx},${c.position.dy}").join("|");
      yield 'COMMANDS:$cmdsString';
      
      final resourceNames = commands.map((c) => c.label).join(' and ');
      yield 'ACTION: Understood. Adding $resourceNames to the canvas...';
    } else {
      yield 'ACTION: I\'m sorry, I didn\'t recognize an architectural command. Try asking to "add an EC2 instance calling an S3 bucket".';
    }
  }
}
