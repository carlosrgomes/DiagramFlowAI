import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:webview_flutter/webview_flutter.dart';

class DiagramExporter {
  WebViewController? _controller;
  Completer<String>? _svgCompleter;
  Completer<String>? _pngCompleter;

  void attach(WebViewController controller) {
    _controller = controller;
  }

  bool get isReady => _controller != null;

  bool handleBridgeMessage(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    if (type == 'exportSvgResult') {
      _svgCompleter?.complete(data['data'] as String? ?? '');
      _svgCompleter = null;
      return true;
    }
    if (type == 'exportPngResult') {
      _pngCompleter?.complete(data['data'] as String? ?? '');
      _pngCompleter = null;
      return true;
    }
    return false;
  }

  Future<String?> getSvg() async {
    final c = _controller;
    if (c == null) return null;
    _svgCompleter = Completer<String>();
    await c.runJavaScript('''
      (function(){
        try {
          const svg = document.querySelector('#diagram svg');
          const out = svg ? new XMLSerializer().serializeToString(svg) : '';
          DiagramBridge.postMessage(JSON.stringify({type: 'exportSvgResult', data: out}));
        } catch(e) {
          DiagramBridge.postMessage(JSON.stringify({type: 'exportSvgResult', data: ''}));
        }
      })();
    ''');
    final svg = await _svgCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => '',
    );
    return svg.isEmpty ? null : svg;
  }

  Future<Uint8List?> getPng() async {
    final c = _controller;
    if (c == null) return null;
    _pngCompleter = Completer<String>();
    await c.runJavaScript('''
      (async function(){
        try {
          const svg = document.querySelector('#diagram svg');
          if (!svg) {
            DiagramBridge.postMessage(JSON.stringify({type: 'exportPngResult', data: ''}));
            return;
          }
          const xml = new XMLSerializer().serializeToString(svg);
          const svg64 = btoa(unescape(encodeURIComponent(xml)));
          const dataUrl = 'data:image/svg+xml;base64,' + svg64;
          const img = new Image();
          await new Promise(function(res, rej){ img.onload = res; img.onerror = rej; img.src = dataUrl; });
          const vb = svg.viewBox && svg.viewBox.baseVal;
          const w = (vb && vb.width) ? vb.width : (svg.clientWidth || 1200);
          const h = (vb && vb.height) ? vb.height : (svg.clientHeight || 800);
          const scale = 2;
          const canvas = document.createElement('canvas');
          canvas.width = Math.ceil(w * scale);
          canvas.height = Math.ceil(h * scale);
          const ctx = canvas.getContext('2d');
          ctx.fillStyle = '#0B1326';
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.scale(scale, scale);
          ctx.drawImage(img, 0, 0, w, h);
          const png = canvas.toDataURL('image/png');
          DiagramBridge.postMessage(JSON.stringify({type: 'exportPngResult', data: png}));
        } catch(e) {
          DiagramBridge.postMessage(JSON.stringify({type: 'exportPngResult', data: ''}));
        }
      })();
    ''');
    final dataUrl = await _pngCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => '',
    );
    if (dataUrl.isEmpty || !dataUrl.contains(',')) return null;
    return base64Decode(dataUrl.split(',').last);
  }
}
