import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'diagram_node.dart';
import 'diagram_state.dart';

class ProjectFile {
  static const int currentVersion = 1;
  static const String kind = 'cloudflow.project';
  static const String extension = 'cloudflow.json';

  static Map<String, dynamic> toJson(DiagramState state) {
    return {
      'version': currentVersion,
      'kind': kind,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'diagram': {
        'code': state.mermaidCode,
        'nodes': state.nodes.values
            .map((n) => {
                  'id': n.id,
                  'label': n.label,
                  'type': n.type.name,
                  if (n.parentId != null) 'parentId': n.parentId,
                  if (n.iconPath != null) 'iconPath': n.iconPath,
                  'shape': n.shape,
                })
            .toList(),
        'edges': state.edges
            .map((e) => {
                  'fromId': e.fromId,
                  'toId': e.toId,
                  if (e.label != null) 'label': e.label,
                })
            .toList(),
      },
    };
  }

  static ProjectPayload parse(String jsonStr) {
    final raw = jsonDecode(jsonStr);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Project file root must be an object');
    }
    if (raw['kind'] != kind) {
      throw FormatException('Not a DiagramFlowAI project file (kind=${raw['kind']})');
    }
    final version = raw['version'];
    if (version is! int || version > currentVersion) {
      throw FormatException('Unsupported project version: $version');
    }
    final diagram = raw['diagram'];
    if (diagram is! Map<String, dynamic>) {
      throw const FormatException('Missing "diagram" object');
    }

    final code = (diagram['code'] as String?) ?? '';
    final nodes = <DiagramNode>[];
    final edges = <DiagramEdge>[];

    final rawNodes = diagram['nodes'];
    if (rawNodes is List) {
      for (final n in rawNodes) {
        if (n is! Map) continue;
        final type = (n['type'] == 'group') ? NodeType.group : NodeType.resource;
        nodes.add(DiagramNode(
          id: n['id'] as String,
          label: n['label'] as String,
          type: type,
          parentId: n['parentId'] as String?,
          iconPath: n['iconPath'] as String?,
          shape: (n['shape'] as String?) ?? 'rect',
        ));
      }
    }

    final rawEdges = diagram['edges'];
    if (rawEdges is List) {
      for (final e in rawEdges) {
        if (e is! Map) continue;
        edges.add(DiagramEdge(
          fromId: e['fromId'] as String,
          toId: e['toId'] as String,
          label: e['label'] as String?,
        ));
      }
    }

    return ProjectPayload(code: code, nodes: nodes, edges: edges);
  }
}

class ProjectPayload {
  final String code;
  final List<DiagramNode> nodes;
  final List<DiagramEdge> edges;

  ProjectPayload({required this.code, required this.nodes, required this.edges});
}

/// Persistent list of recently opened/saved project paths.
class RecentFiles extends ChangeNotifier {
  static const _kFile = 'recent_files.json';
  static const _maxEntries = 10;

  final List<String> _paths = [];
  bool _loaded = false;

  List<String> get paths => List.unmodifiable(_paths);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final raw = jsonDecode(await file.readAsString());
      if (raw is Map && raw['recent'] is List) {
        for (final p in (raw['recent'] as List)) {
          if (p is String && p.isNotEmpty) _paths.add(p);
        }
        notifyListeners();
      }
    } catch (e) {
      dev.log('[RecentFiles] load failed: $e');
    }
  }

  Future<void> push(String path) async {
    if (!_loaded) await load();
    _paths.remove(path);
    _paths.insert(0, path);
    if (_paths.length > _maxEntries) {
      _paths.removeRange(_maxEntries, _paths.length);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String path) async {
    if (!_loaded) await load();
    if (_paths.remove(path)) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode({'recent': _paths}));
    } catch (e) {
      dev.log('[RecentFiles] save failed: $e');
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$_kFile');
  }
}

/// File picker + filesystem operations. UI-agnostic.
class ProjectIO {
  static Future<String?> pickOpenPath() async {
    final res = await FilePicker.pickFiles(
      dialogTitle: 'Open DiagramFlowAI project',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return res?.files.single.path;
  }

  static Future<String?> pickSavePath({String? suggestedName}) async {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final name = suggestedName ?? 'diagram-$stamp.${ProjectFile.extension}';
    return FilePicker.saveFile(
      dialogTitle: 'Save DiagramFlowAI project',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  }

  static Future<void> writeJson(String path, Map<String, dynamic> json) async {
    final file = File(path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  static Future<String> readString(String path) {
    return File(path).readAsString();
  }
}
