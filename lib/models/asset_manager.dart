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
  static const String _awsRoot = 'assets/aws_icons';

  static String get ec2 => '$_awsRoot/ec2.png';
  static String get s3 => '$_awsRoot/s3.png';
  static String get rds => '$_awsRoot/rds.png';
  static String get vpc => '$_awsRoot/vpc.png';
  static String get lambda => '$_awsRoot/lambda.png';

  static Map<String, List<ResourceTemplate>> _catalog = {};

  static Map<String, List<ResourceTemplate>> get catalog => _catalog;

  static Future<void> loadCatalog() async {
    try {
      final manifest = await rootBundle.loadString('assets/aws_assets_list.txt');
      final lines = manifest.split('\n');
      
      Map<String, List<ResourceTemplate>> newCatalog = {};

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        // Path example: assets/aws/Resource-Icons_07312025/Res_Compute/Res_Amazon-EC2_Instance_48.png
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
    } catch (e) {
      dev.log('Error loading asset catalog: $e');
    }
  }

  static String getIconForLabel(String label) {
    final l = label.toUpperCase();
    if (l.contains('EC2')) return ec2;
    if (l.contains('RDS')) return rds;
    if (l.contains('S3')) return s3;
    if (l.contains('VPC')) return vpc;
    if (l.contains('LAMBDA')) return lambda;
    return ec2;
  }
}
