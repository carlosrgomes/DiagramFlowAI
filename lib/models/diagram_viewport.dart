import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DiagramViewport extends ChangeNotifier {
  static const double _minZoom = 0.25;
  static const double _maxZoom = 4.0;
  static const double _step = 1.2;

  WebViewController? _controller;
  double _zoom = 1.0;
  bool _panMode = false;

  void attach(WebViewController controller) {
    _controller = controller;
  }

  double get zoom => _zoom;
  bool get panMode => _panMode;

  void zoomIn() => _setZoom(_zoom * _step);
  void zoomOut() => _setZoom(_zoom / _step);
  void resetZoom() => _setZoom(1.0);

  void togglePan() {
    _panMode = !_panMode;
    _push();
    notifyListeners();
  }

  void _setZoom(double next) {
    final clamped = next.clamp(_minZoom, _maxZoom);
    if (clamped == _zoom) return;
    _zoom = clamped;
    _push();
    notifyListeners();
  }

  void _push() {
    final c = _controller;
    if (c == null) return;
    c.runJavaScript(
      'if (window.__viewport) window.__viewport.apply($_zoom, $_panMode);',
    );
  }
}
