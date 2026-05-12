import 'package:diagram_flow_ai/models/ai_model_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final state = AIModelState();

  group('extractMermaidCode', () {
    test('preferred path: extracts content between <DIAGRAM>...</DIAGRAM> tags', () {
      const response = '''
Here is the diagram:

<DIAGRAM>
flowchart TD
    A --> B
</DIAGRAM>
''';
      final out = state.extractMermaidCode(response);
      expect(out, 'flowchart TD\n    A --> B');
    });

    test('tags win over markdown fences if both present', () {
      const response = '''
<DIAGRAM>
flowchart TD
    Real --> Diagram
</DIAGRAM>

```mermaid
flowchart TD
    Decoy --> Should not pick this
```
''';
      final out = state.extractMermaidCode(response);
      expect(out, contains('Real --> Diagram'));
      expect(out, isNot(contains('Decoy')));
    });

    test('fallback: extracts from ```mermaid fenced block when no tags', () {
      const response = '''
Here:
```mermaid
flowchart TD
    A --> B
```
''';
      final out = state.extractMermaidCode(response);
      expect(out, 'flowchart TD\n    A --> B');
    });

    test('fallback: extracts when fence language is anything (e.g. architecture-beta)', () {
      const response = '''
```architecture-beta
group api(cloud)[API]
service web(server)[Web] in api
```
''';
      final out = state.extractMermaidCode(response);
      expect(out, isNotNull);
      expect(out, contains('group api'));
      expect(out, contains('service web'));
    });

    test('returns null when neither tags nor fence found', () {
      expect(state.extractMermaidCode('just some prose'), isNull);
    });

    test('returns null when tags are open-ended (no closing tag)', () {
      const response = '''
<DIAGRAM>
flowchart TD
    A --> B
no closing tag here
''';
      // Tag form fails (no closing), but no fence either → null
      expect(state.extractMermaidCode(response), isNull);
    });

    test('handles tags inside larger reasoning prose without leaking commentary', () {
      const response = '''
Let me think about this. I'll use a flowchart with subgraphs.

The architecture has a load balancer feeding two regions.

<DIAGRAM>
flowchart TD
    LB[HTTPS LB] --> CR1[Cloud Run us-central1]
    LB --> CR2[Cloud Run us-east1]
</DIAGRAM>

This shows the dual-region setup with shared backends.
''';
      final out = state.extractMermaidCode(response);
      expect(out, isNotNull);
      expect(out, contains('LB[HTTPS LB]'));
      expect(out, isNot(contains('Let me think')));
      expect(out, isNot(contains('This shows')));
    });
  });
}
