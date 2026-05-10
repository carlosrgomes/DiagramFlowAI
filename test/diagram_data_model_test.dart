import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/models/diagram_node.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';

void main() {
  group('DiagramNode Data Model', () {
    test('should create a resource node with default parentId null', () {
      final node = DiagramNode(
        id: 'node1',
        label: 'EC2 Instance',
        type: NodeType.resource,
      );

      expect(node.id, 'node1');
      expect(node.label, 'EC2 Instance');
      expect(node.type, NodeType.resource);
      expect(node.parentId, isNull);
    });

    test('should create a group node with a parentId', () {
      final node = DiagramNode(
        id: 'subnet1',
        label: 'Public Subnet',
        type: NodeType.group,
        parentId: 'vpc1',
      );

      expect(node.type, NodeType.group);
      expect(node.parentId, 'vpc1');
    });
  });

  group('DiagramState Hierarchical Support', () {
    test('should add a node to internal state and reflect in Mermaid code', () {
      final state = DiagramState();
      state.addNodeWithParent(
        id: 'ec2_1',
        label: 'Web Server',
        type: NodeType.resource,
      );

      expect(state.nodes.length, 1);
      expect(state.nodes['ec2_1']?.label, 'Web Server');
      expect(state.mermaidCode, contains('ec2_1[Web Server]'));
    });

    test('should handle subgraphs for group nodes', () {
      final state = DiagramState();
      state.addNodeWithParent(
        id: 'vpc1',
        label: 'My VPC',
        type: NodeType.group,
      );
      state.addNodeWithParent(
        id: 'ec2_1',
        label: 'Web Server',
        type: NodeType.resource,
        parentId: 'vpc1',
      );

      expect(state.nodes['ec2_1']?.parentId, 'vpc1');
      // Mermaid subgraph syntax
      expect(state.mermaidCode, contains('subgraph vpc1 [My VPC]'));
      expect(state.mermaidCode, contains('ec2_1[Web Server]'));
      expect(state.mermaidCode, contains('end'));
    });
  });
}
