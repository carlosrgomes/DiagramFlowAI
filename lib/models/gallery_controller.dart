import 'package:flutter/foundation.dart';

/// Controls visibility of the Templates gallery overlay. Lifted to a provider
/// so the TopNavBar button, AppShell shortcut (Cmd+T), and DiagramCanvas
/// auto-open/close listener can all share one source of truth.
class GalleryController extends ChangeNotifier {
  bool _isOpen = true;
  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }
}
