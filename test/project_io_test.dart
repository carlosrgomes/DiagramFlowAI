import 'dart:convert';

import 'package:diagram_flow_ai/models/diagram_node.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';
import 'package:diagram_flow_ai/models/project_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagramState undo/redo', () {
    test('starts with no history', () {
      final s = DiagramState();
      expect(s.canUndo, isFalse);
      expect(s.canRedo, isFalse);
    });

    test('addNode pushes a snapshot, undo reverts', () async {
      final s = DiagramState();
      await s.addNodeWithParent(id: 'foo', label: 'Foo', type: NodeType.resource);
      expect(s.nodes.containsKey('foo'), isTrue);
      expect(s.canUndo, isTrue);

      s.undo();
      expect(s.nodes.containsKey('foo'), isFalse);
      expect(s.canRedo, isTrue);

      s.redo();
      expect(s.nodes.containsKey('foo'), isTrue);
    });

    test('explicit pushSnapshot batches multiple mutations into one undo', () async {
      final s = DiagramState();
      s.pushSnapshot();
      await s.addNodeWithParent(id: 'a', label: 'A', type: NodeType.resource, snapshot: false);
      await s.addNodeWithParent(id: 'b', label: 'B', type: NodeType.resource, snapshot: false);
      s.addEdge('a', 'b', snapshot: false);
      expect(s.nodes.length, 2);
      expect(s.edges.length, 1);

      s.undo();
      expect(s.nodes, isEmpty);
      expect(s.edges, isEmpty);
    });

    test('mutating after undo clears redo stack', () async {
      final s = DiagramState();
      await s.addNodeWithParent(id: 'a', label: 'A', type: NodeType.resource);
      s.undo();
      expect(s.canRedo, isTrue);

      await s.addNodeWithParent(id: 'b', label: 'B', type: NodeType.resource);
      expect(s.canRedo, isFalse);
    });
  });

  group('Project save/load round-trip', () {
    test('serializes and parses back to equivalent state', () async {
      final original = DiagramState();
      await original.addNodeWithParent(id: 'vpc', label: 'My VPC', type: NodeType.group);
      await original.addNodeWithParent(
        id: 'ec2',
        label: 'EC2',
        type: NodeType.resource,
        parentId: 'vpc',
        iconPath: 'assets/icons/ec2.png',
      );
      original.addEdge('ec2', 'vpc', label: 'inside');

      final json = ProjectFile.toJson(original);
      final encoded = jsonEncode(json);
      final payload = ProjectFile.parse(encoded);

      expect(payload.nodes.length, 2);
      expect(payload.edges.length, 1);
      final ec2 = payload.nodes.firstWhere((n) => n.id == 'ec2');
      expect(ec2.parentId, 'vpc');
      expect(ec2.iconPath, 'assets/icons/ec2.png');
      expect(payload.edges.first.label, 'inside');
    });

    test('rejects files with wrong kind', () {
      final bad = jsonEncode({'kind': 'something.else', 'version': 1, 'diagram': {}});
      expect(() => ProjectFile.parse(bad), throwsFormatException);
    });

    test('rejects future versions', () {
      final bad = jsonEncode({
        'kind': 'cloudflow.project',
        'version': 999,
        'diagram': {'code': '', 'nodes': [], 'edges': []},
      });
      expect(() => ProjectFile.parse(bad), throwsFormatException);
    });
  });

  group('DiagramState dirty tracking', () {
    test('starts clean, becomes dirty on mutation, clean on save', () async {
      final s = DiagramState();
      expect(s.isDirty, isFalse);

      await s.addNodeWithParent(id: 'a', label: 'A', type: NodeType.resource);
      expect(s.isDirty, isTrue);

      s.markSaved('/tmp/test.cloudflow.json');
      expect(s.isDirty, isFalse);
      expect(s.currentFilePath, '/tmp/test.cloudflow.json');
    });

    test('newProject resets path and dirty flag', () async {
      final s = DiagramState();
      await s.addNodeWithParent(id: 'a', label: 'A', type: NodeType.resource);
      s.markSaved('/tmp/x.json');
      s.newProject();
      expect(s.currentFilePath, isNull);
      expect(s.isDirty, isFalse);
      expect(s.canUndo, isFalse);
    });
  });
}
