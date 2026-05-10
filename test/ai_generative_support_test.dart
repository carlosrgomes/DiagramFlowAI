import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/diagram_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Generative Support Command Parsing', () {
    test('should parse NODE and GROUP commands correctly', () async {
      final aiState = AIModelState();
      final diagramState = DiagramState();
      
      const commands = 'GROUP:My VPC@vpc1@null\n'
          'NODE:EC2 Instance@ec2_1@vpc1@null';
      
      await aiState.parseAndApplyCommands(commands, diagramState);
      
      expect(diagramState.nodes.containsKey('vpc1'), isTrue);
      expect(diagramState.nodes['vpc1']?.type, NodeType.group);
      expect(diagramState.nodes.containsKey('ec2_1'), isTrue);
      expect(diagramState.nodes['ec2_1']?.parentId, 'vpc1');
      expect(diagramState.mermaidCode, contains('subgraph vpc1 ["My VPC"]'));
    });

    test('should parse EDGE commands correctly', () async {
      final aiState = AIModelState();
      final diagramState = DiagramState();
      
      const commands = 'NODE:Start@A@null@null\n'
          'NODE:End@B@null@null\n'
          'EDGE:A@B@Connect';
      
      await aiState.parseAndApplyCommands(commands, diagramState);
      
      expect(diagramState.edges.length, 1);
      expect(diagramState.edges.first.fromId, 'A');
      expect(diagramState.edges.first.toId, 'B');
      expect(diagramState.mermaidCode, contains('A -->|Connect| B'));
    });
  });
}
