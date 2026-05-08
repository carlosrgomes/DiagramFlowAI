import 'dart:developer' as dev;
import 'package:flutter/services.dart';

class ResourceTemplate {
  final String label;
  final String path;
  final String category;

  ResourceTemplate({
    required this.label,
    required this.path,
    required this.category,
  });
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

        newCatalog[categoryPart]!.add(ResourceTemplate(
          label: label,
          path: line,
          category: categoryPart,
        ));
      }

      _catalog = newCatalog;
      dev.log('Asset catalog loaded with ${_catalog.length} categories.');
    } catch (e) {
      dev.log('Error loading asset catalog: $e');
    }
  }

  static String getIconForLabel(String label) {
    final l = label.toUpperCase().replaceAll(' ', '');
    
    // Try to find in dynamic catalog first
    for (var category in _catalog.values) {
      for (var resource in category) {
        final resourceLabel = resource.label.toUpperCase().replaceAll(' ', '');
        if (resourceLabel.contains(l) || l.contains(resourceLabel)) {
          return resource.path;
        }
      }
    }

    // Common abbreviations
    if (l.contains('EC2')) return _findInCatalog('EC2');
    if (l.contains('RDS')) return _findInCatalog('RDS');
    if (l.contains('S3')) return _findInCatalog('S3');
    if (l.contains('VPC')) return _findInCatalog('VPC');
    if (l.contains('LAMBDA')) return _findInCatalog('Lambda');
    
    return _catalog.values.first.first.path; // Absolute fallback to any valid asset
  }

  static String _findInCatalog(String keyword) {
    for (var category in _catalog.values) {
      for (var resource in category) {
        if (resource.label.toUpperCase().contains(keyword.toUpperCase())) {
          return resource.path;
        }
      }
    }
    return '';
  }
}
