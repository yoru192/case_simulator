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
            onTap: () {
              onItemTap(entry.key);
              Navigator.pop(context);
            },
            title: Text(entry.value),
          ),
        )
            .toList(),
      ),
    );
  }
}
