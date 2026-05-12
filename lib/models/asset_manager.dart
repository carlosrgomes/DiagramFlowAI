import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResourceTemplate {
  final String label;
  final String? path;    // null for Mermaid-native shape items
  final String category;
  final String shape;    // mermaid shape key
  final IconData? icon;  // Flutter icon shown when no image asset

  const ResourceTemplate({
    required this.label,
    this.path,
    this.category = 'Shapes',
    this.shape = 'rect',
    this.icon,
  });
}

/// Built-in Mermaid shape palette — always available for drag-and-drop.
/// Shape keys map to Mermaid v11 `@{ shape: ... }` syntax.
const mermaidShapeTemplates = <ResourceTemplate>[
  // ── Basic ──
  ResourceTemplate(label: 'Process',     shape: 'rect',           icon: Icons.crop_square_sharp,    category: 'Basic'),
  ResourceTemplate(label: 'Rounded',     shape: 'rounded',        icon: Icons.crop_square,          category: 'Basic'),
  ResourceTemplate(label: 'Terminal',    shape: 'stadium',        icon: Icons.panorama_wide_angle,  category: 'Basic'),
  ResourceTemplate(label: 'Subroutine',  shape: 'subproc',        icon: Icons.dns_outlined,         category: 'Basic'),
  ResourceTemplate(label: 'Database',    shape: 'cyl',            icon: Icons.storage,              category: 'Basic'),
  ResourceTemplate(label: 'Disk',        shape: 'lin-cyl',        icon: Icons.album_outlined,       category: 'Basic'),
  ResourceTemplate(label: 'Circle',      shape: 'circle',         icon: Icons.circle_outlined,      category: 'Basic'),
  ResourceTemplate(label: 'Sm Circle',   shape: 'sm-circ',        icon: Icons.fiber_manual_record,  category: 'Basic'),
  ResourceTemplate(label: 'Dbl Circle',  shape: 'dbl-circ',       icon: Icons.adjust,               category: 'Basic'),
  ResourceTemplate(label: 'Decision',    shape: 'diam',           icon: Icons.change_history,       category: 'Basic'),
  ResourceTemplate(label: 'Hexagon',     shape: 'hex',            icon: Icons.hexagon_outlined,     category: 'Basic'),

  // ── Flow IO ──
  ResourceTemplate(label: 'Input',       shape: 'lean-r',         icon: Icons.east,                 category: 'Flow IO'),
  ResourceTemplate(label: 'Output',      shape: 'lean-l',         icon: Icons.west,                 category: 'Flow IO'),
  ResourceTemplate(label: 'Manual In',   shape: 'sl-rect',        icon: Icons.keyboard_outlined,    category: 'Flow IO'),
  ResourceTemplate(label: 'Manual Op',   shape: 'trap-t',         icon: Icons.pan_tool_outlined,    category: 'Flow IO'),
  ResourceTemplate(label: 'Prepare',     shape: 'hex',            icon: Icons.build_outlined,       category: 'Flow IO'),
  ResourceTemplate(label: 'Display',     shape: 'curv-trap',      icon: Icons.desktop_windows,      category: 'Flow IO'),
  ResourceTemplate(label: 'Delay',       shape: 'delay',          icon: Icons.hourglass_bottom,     category: 'Flow IO'),

  // ── Documents ──
  ResourceTemplate(label: 'Document',    shape: 'doc',            icon: Icons.description_outlined, category: 'Docs'),
  ResourceTemplate(label: 'Multi Doc',   shape: 'docs',           icon: Icons.collections_bookmark, category: 'Docs'),
  ResourceTemplate(label: 'Tagged Doc',  shape: 'tag-doc',        icon: Icons.bookmark_outline,     category: 'Docs'),
  ResourceTemplate(label: 'Lined Doc',   shape: 'lin-doc',        icon: Icons.article_outlined,     category: 'Docs'),
  ResourceTemplate(label: 'Paper Tape',  shape: 'paper-tape',     icon: Icons.receipt_long,         category: 'Docs'),

  // ── Control ──
  ResourceTemplate(label: 'Start',       shape: 'circle',         icon: Icons.play_circle_outline,  category: 'Control'),
  ResourceTemplate(label: 'Stop',        shape: 'dbl-circ',       icon: Icons.stop_circle_outlined, category: 'Control'),
  ResourceTemplate(label: 'Fork/Join',   shape: 'fork',           icon: Icons.call_split,           category: 'Control'),
  ResourceTemplate(label: 'Junction',    shape: 'sm-circ',        icon: Icons.lens,                 category: 'Control'),
  ResourceTemplate(label: 'Comment',     shape: 'brace',          icon: Icons.comment_outlined,     category: 'Control'),
  ResourceTemplate(label: 'Lightning',   shape: 'bolt',           icon: Icons.bolt,                 category: 'Control'),
  ResourceTemplate(label: 'Tag',         shape: 'tag-rect',       icon: Icons.label_outline,        category: 'Control'),
  ResourceTemplate(label: 'Card',        shape: 'notch-rect',     icon: Icons.credit_card,          category: 'Control'),
];

/// Same templates grouped by category (preserves insertion order).
Map<String, List<ResourceTemplate>> get groupedShapeTemplates {
  final m = <String, List<ResourceTemplate>>{};
  for (final t in mermaidShapeTemplates) {
    m.putIfAbsent(t.category, () => []).add(t);
  }
  return m;
}

class AssetManager {
  static Map<String, List<ResourceTemplate>> _catalog = {};

  static Map<String, List<ResourceTemplate>> get catalog => _catalog;

  static Future<void> loadCatalog() async {
    try {
      final manifest = await rootBundle.loadString('assets/aws_assets_list.txt');
      final lines = manifest.split('\n');
      
      Map<String, List<ResourceTemplate>> newCatalog = {};

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.split('/');
        if (parts.length < 4) continue;

        final categoryPart = parts[parts.length - 2].replaceFirst('Res_', '');
        final fileName = parts.last;
        final label = fileName
            .replaceFirst('Res_', '')
            .replaceFirst('_48.png', '')
            .replaceAll('-', ' ')
            .replaceAll('_', ' ');

        if (!newCatalog.containsKey(categoryPart)) {
          newCatalog[categoryPart] = [];
        }

        final cat = categoryPart.toLowerCase();
        final shape = (cat.contains('storage') || cat.contains('database') || cat.contains('db'))
            ? 'cylinder'
            : 'rect';
        newCatalog[categoryPart]!.add(ResourceTemplate(
          label: label,
          path: line,
          category: categoryPart,
          shape: shape,
        ));
      }

      _catalog = newCatalog;
      dev.log('Asset catalog loaded with ${_catalog.length} categories.');
    } catch (e) {
      dev.log('Error loading asset catalog: $e');
    }
  }

  static String? getIconForLabel(String label) {
    final l = label.toUpperCase().replaceAll(' ', '');

    for (var category in _catalog.values) {
      for (var resource in category) {
        final resourceLabel = resource.label.toUpperCase().replaceAll(' ', '');
        if (resourceLabel.contains(l) || l.contains(resourceLabel)) {
          return resource.path;
        }
      }
    }

    if (l.contains('EC2')) return _findInCatalog('EC2');
    if (l.contains('RDS')) return _findInCatalog('RDS');
    if (l.contains('S3')) return _findInCatalog('S3');
    if (l.contains('VPC')) return _findInCatalog('VPC');
    if (l.contains('LAMBDA')) return _findInCatalog('Lambda');

    return _catalog.values.isNotEmpty ? _catalog.values.first.first.path : null;
  }

  static String? _findInCatalog(String keyword) {
    for (var category in _catalog.values) {
      for (var resource in category) {
        if (resource.label.toUpperCase().contains(keyword.toUpperCase())) {
          return resource.path;
        }
      }
    }
    return null;
  }
}
