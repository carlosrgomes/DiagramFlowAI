import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_flow_ai/models/diagram_state.dart';

void main() {
  group('DiagramState', () {
    test('initial state has default mermaid code', () {
      final state = DiagramState();
      expect(state.mermaidCode, contains('flowchart TD'));
    });

    test('setCode updates mermaidCode', () {
      final state = DiagramState();
      state.setCode('flowchart LR\n    A --> B');
      expect(state.mermaidCode, 'flowchart LR\n    A --> B');
    });

    test('setCode notifies listeners', () {
      final state = DiagramState();
      bool notified = false;
      state.addListener(() => notified = true);
      state.setCode('flowchart TD\n    X --> Y');
      expect(notified, isTrue);
    });

    test('setCode with same value does not notify', () {
      final state = DiagramState();
      final initial = state.mermaidCode;
      int count = 0;
      state.addListener(() => count++);
      state.setCode(initial);
      expect(count, 0);
    });

    test('addNode appends node to mermaid code', () {
      final state = DiagramState();
      state.addNode('srv', 'Server');
      expect(state.mermaidCode, contains('srv["Server"]'));
    });

    test('addEdge appends edge to mermaid code', () {
      final state = DiagramState();
      state.addEdge('A', 'B');
      expect(state.mermaidCode, contains('A --> B'));
    });

    test('addEdge with label uses labelled arrow', () {
      final state = DiagramState();
      state.addEdge('A', 'B', label: 'calls');
      expect(state.mermaidCode, contains('-->|calls|'));
    });

    test('clearDiagram resets to minimal flowchart', () {
      final state = DiagramState();
      state.setCode('flowchart LR\n    A --> B --> C --> D');
      state.clearDiagram();
      expect(state.mermaidCode, contains('flowchart TD'));
    });
  });
}
