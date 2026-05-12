import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

class MermaidValidation {
  final bool ok;
  final String? error;
  const MermaidValidation({required this.ok, this.error});
}

/// Calls `mermaid.parse(code)` inside the WebView (without rendering) and
/// returns whether the code is syntactically valid. Used by the ReAct retry
/// loop to validate AI output before it ever hits the canvas.
class MermaidValidator {
  WebViewController? _controller;
  final Map<String, Completer<MermaidValidation>> _pending = {};
  int _seq = 0;

  void attach(WebViewController controller) {
    _controller = controller;
  }

  bool get isReady => _controller != null;

  Future<MermaidValidation> validate(String code) async {
    final c = _controller;
    if (c == null) {
      return const MermaidValidation(ok: false, error: 'Validator not attached');
    }
    final id = '${++_seq}';
    final completer = Completer<MermaidValidation>();
    _pending[id] = completer;
    // Escape for JS template literal: backslashes, backticks, AND `${...}`
    // (Mermaid output can contain `$` legitimately and would otherwise be
    // evaluated as JS interpolation, breaking runJavaScript).
    final escaped = code
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$');
    try {
      await c.runJavaScript('validateMermaid(`$escaped`, "$id")');
    } catch (e) {
      _pending.remove(id);
      return MermaidValidation(ok: false, error: 'Validator runJavaScript failed: $e');
    }
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _pending.remove(id);
        return const MermaidValidation(ok: false, error: 'Validation timed out');
      },
    );
  }

  /// Returns true if this message was a validateResult and was handled.
  bool handleBridgeMessage(Map<String, dynamic> data) {
    if (data['type'] != 'validateResult') return false;
    final id = data['id'] as String?;
    if (id == null) return true;
    final completer = _pending.remove(id);
    if (completer == null) return true;
    completer.complete(MermaidValidation(
      ok: data['ok'] as bool? ?? false,
      error: data['error'] as String?,
    ));
    return true;
  }
}
