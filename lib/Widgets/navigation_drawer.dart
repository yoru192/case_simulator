import 'package:case_simulator/Pages/ranks_screen.dart';
import 'package:flutter/material.dart';

class AppNavigationDrawer extends StatelessWidget {
  final List<String> menuItems;
  final Function(int) onItemTap;

  const AppNavigationDrawer({
    super.key,
    required this.menuItems,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: menuItems
            .asMap()
            .entries
            .map(
              (entry) => ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: const Text('Ранги'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RanksScreen()),
                  );
                },
              ),
        )
            .toList(),
      ),
    );
  }
}
