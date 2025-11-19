import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  final List<String> menuItems;
  final Function(int) onItemTap;

  const AppNavigationBar({
    super.key,
    required this.menuItems,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: menuItems
          .asMap()
          .entries
          .map(
            (entry) => InkWell(
          onTap: () => onItemTap(entry.key),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16,
            ),
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}
