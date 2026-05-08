import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';

void main() {
  group('DiagramState', () {
    test('initial state has no nodes', () {
      final state = DiagramState();
      expect(state.nodes, isEmpty);
    });

    test('addNode adds a node to the list', () {
      final state = DiagramState();
      state.addNode(
        id: 'node-1',
        label: 'Compute Instance',
        position: const Offset(100, 100),
      );
      expect(state.nodes.length, 1);
      expect(state.nodes.first.id, 'node-1');
      expect(state.nodes.first.position, const Offset(100, 100));
    });

    test('updateNodePosition updates position correctly', () {
      final state = DiagramState();
      state.addNode(
        id: 'node-1',
        label: 'Compute Instance',
        position: const Offset(100, 100),
      );
      
      state.updateNodePosition('node-1', const Offset(200, 200));
      expect(state.nodes.first.position, const Offset(200, 200));
    });
  });
}
