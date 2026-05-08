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
    
    yield 'THOUGHT: Parsing architectural request and identifying primary components...';
    await Future.delayed(const Duration(milliseconds: 800));
    
    Map<String, String> resourceIds = {};
    List<String> nodeCommands = [];
    
    // Check for resources and generate IDs
    if (input.contains('ec2') || input.contains('instance')) {
      yield 'THOUGHT: Detected Compute node (EC2). Assigning coordinates.';
      final id = 'node_ec2_${DateTime.now().microsecondsSinceEpoch}';
      resourceIds['ec2'] = id;
      final pos = Offset(200.0 + random.nextDouble() * 100, 250.0 + random.nextDouble() * 100);
      nodeCommands.add("NODE:EC2@${pos.dx},${pos.dy}@$id");
      await Future.delayed(const Duration(milliseconds: 400));
    }
    
    if (input.contains('s3') || input.contains('bucket')) {
      yield 'THOUGHT: Detected Storage node (S3). Assigning coordinates.';
      final id = 'node_s3_${DateTime.now().microsecondsSinceEpoch}';
      resourceIds['s3'] = id;
      final pos = Offset(450.0 + random.nextDouble() * 100, 250.0 + random.nextDouble() * 100);
      nodeCommands.add("NODE:S3@${pos.dx},${pos.dy}@$id");
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (input.contains('rds') || input.contains('database')) {
      yield 'THOUGHT: Detected Database node (RDS). Assigning coordinates.';
      final id = 'node_rds_${DateTime.now().microsecondsSinceEpoch}';
      resourceIds['rds'] = id;
      final pos = Offset(350.0 + random.nextDouble() * 100, 450.0 + random.nextDouble() * 100);
      nodeCommands.add("NODE:RDS@${pos.dx},${pos.dy}@$id");
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (input.contains('vpc') || input.contains('network')) {
      yield 'THOUGHT: Detected Network boundary (VPC).';
      final id = 'node_vpc_${DateTime.now().microsecondsSinceEpoch}';
      resourceIds['vpc'] = id;
      final pos = Offset(100.0, 100.0);
      nodeCommands.add("NODE:VPC@${pos.dx},${pos.dy}@$id");
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // Emit all found nodes
    for (final cmd in nodeCommands) {
      yield cmd;
    }

    // Handle Connections
    if (input.contains('chamando') || input.contains('connect') || input.contains('call') || input.contains('->')) {
      yield 'THOUGHT: Establishing logical connections between identified components...';
      await Future.delayed(const Duration(milliseconds: 800));

      if (resourceIds.containsKey('ec2') && resourceIds.containsKey('s3')) {
        yield 'CONN:${resourceIds['ec2']}->${resourceIds['s3']}';
        yield 'THOUGHT: Created link: EC2 calls S3.';
      }
      if (resourceIds.containsKey('ec2') && resourceIds.containsKey('rds')) {
        yield 'CONN:${resourceIds['ec2']}->${resourceIds['rds']}';
        yield 'THOUGHT: Created link: EC2 queries RDS.';
      }
    }

    if (nodeCommands.isNotEmpty) {
      yield 'ACTION: Diagram successfully generated with ${nodeCommands.length} resources and connections.';
    } else {
      yield 'ACTION: I couldn\'t identify any AWS resources in your prompt. Try "desenhe ec2 chamando s3".';
    }
  }
}
