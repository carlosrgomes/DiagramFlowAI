import 'package:flutter/material.dart';

class ResourceTemplate {
  final String label;
  final IconData icon;
  final Color color;

  ResourceTemplate({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class ResourceSidebar extends StatelessWidget {
  const ResourceSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = {
      'Compute': [
        ResourceTemplate(label: 'EC2 Instance', icon: Icons.memory, color: Colors.orange),
        ResourceTemplate(label: 'Lambda Function', icon: Icons.bolt, color: Colors.orange),
      ],
      'Storage': [
        ResourceTemplate(label: 'S3 Bucket', icon: Icons.storage, color: Colors.green),
        ResourceTemplate(label: 'RDS Database', icon: Icons.dns, color: Colors.blue),
      ],
      'Network': [
        ResourceTemplate(label: 'VPC', icon: Icons.cloud_queue, color: Colors.purple),
        ResourceTemplate(label: 'Load Balancer', icon: Icons.settings_input_component, color: Colors.purple),
      ],
    };

    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Resource Library',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: categories.entries.map((category) {
                return ExpansionTile(
                  title: Text(
                    category.key,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  initiallyExpanded: true,
                  children: category.value.map((template) {
                    return ListTile(
                      leading: Icon(template.icon, color: template.color),
                      title: Text(template.label),
                      onTap: () {}, // Will handle drag start later
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
