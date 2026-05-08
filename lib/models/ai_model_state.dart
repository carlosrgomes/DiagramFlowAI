import 'package:flutter/material.dart';

enum AIModelStatus {
  notDownloaded,
  downloading,
  ready,
}

class AIModelState extends ChangeNotifier {
  AIModelStatus _status = AIModelStatus.notDownloaded;
  double _downloadProgress = 0.0;

  AIModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;

  Future<void> startDownload() async {
    if (_status != AIModelStatus.notDownloaded) return;

    _status = AIModelStatus.downloading;
    _downloadProgress = 0.0;
    notifyListeners();

    // Simulate download
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      _downloadProgress = i / 100.0;
      notifyListeners();
    }

    _status = AIModelStatus.ready;
    notifyListeners();
  }
}
