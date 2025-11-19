import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/item.dart';

class InventoryScreen extends StatelessWidget {
  final Box<ItemModel> inventoryBox;

  const InventoryScreen({
    super.key,
    required this.inventoryBox,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: inventoryBox.listenable(),
      builder: (context, Box<ItemModel> box, _) {
        if (box.isEmpty) {
          return const _EmptyInventoryView();
        }

        return _InventoryContent(box: box);
      },
    );
  }
}

class _EmptyInventoryView extends StatelessWidget {
  const _EmptyInventoryView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Інвентар порожній",
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class _InventoryContent extends StatelessWidget {
  final Box<ItemModel> box;

  const _InventoryContent({required this.box});

  @override
  Widget build(BuildContext context) {
    final totalValue = box.values.fold(0.0, (sum, item) => sum + item.price);

    return Column(
      children: [
        _InventoryHeader(
          itemCount: box.length,
          totalValue: totalValue,
        ),
        Expanded(
          child: _InventoryGrid(box: box),
        ),
      ],
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  final int itemCount;
  final double totalValue;

  const _InventoryHeader({
    required this.itemCount,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Всього предметів: $itemCount',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Сума: \$${totalValue.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  final Box<ItemModel> box;

  const _InventoryGrid({required this.box});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: box.length,
      itemBuilder: (context, index) {
        final item = box.getAt(index);
        return _InventoryItemCard(item: item);
      },
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final ItemModel? item;

  const _InventoryItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 40),
          const SizedBox(height: 8),
          Text(
            item?.weapon ?? 'Unknown',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            item?.skin ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${item?.price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
          Text(
            item?.rarity ?? '',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
