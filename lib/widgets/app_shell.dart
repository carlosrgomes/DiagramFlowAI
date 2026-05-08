import 'package:diagram_flow_ai/widgets/diagram_canvas.dart';
import 'package:diagram_flow_ai/widgets/resource_sidebar.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const Row(
          children: [
            ResourceSidebar(),
            VerticalDivider(thickness: 1, width: 1),
            Expanded(child: DiagramCanvas()),
          ],
        );
      case 1:
        return const Center(
          child: Text(
            'Settings View',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      default:
        return const Center(child: Text('Not Found'));
    }
  }
}
