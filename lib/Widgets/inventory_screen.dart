import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/item.dart';
import 'package:case_simulator/services/balance_service.dart';
import 'package:case_simulator/services/auth_service.dart';
import 'package:case_simulator/widgets/balance_widget.dart';

enum SortBy { priceDesc, priceAsc, newest, oldest }
enum RarityFilter { all, covert, classified, restricted, milSpec }

class InventoryScreen extends StatelessWidget {
  final Box<ItemModel> inventoryBox;

  const InventoryScreen({
    super.key,
    required this.inventoryBox,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      return const Center(child: Text('Не авторизований'));
    }

    return ValueListenableBuilder(
      valueListenable: inventoryBox.listenable(),
      builder: (context, Box<ItemModel> box, _) {
        final userItems = box.values
            .where((item) => item.userId == currentUser.id)
            .toList();

        if (userItems.isEmpty) {
          return const _EmptyInventoryView();
        }

        return _InventoryContent(items: userItems);
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

class _InventoryContent extends StatefulWidget {
  final List<ItemModel> items;

  const _InventoryContent({required this.items});

  @override
  State<_InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<_InventoryContent> {
  SortBy _sortBy = SortBy.newest;
  RarityFilter _rarityFilter = RarityFilter.all;

  List<ItemModel> get _filteredAndSortedItems {
    var items = List<ItemModel>.from(widget.items);

    // Фільтрація за рідкістю
    if (_rarityFilter != RarityFilter.all) {
      items = items.where((item) {
        final rarity = item.rarity.toLowerCase();
        switch (_rarityFilter) {
          case RarityFilter.covert:
            return rarity.contains('covert') || rarity.contains('extraordinary');
          case RarityFilter.classified:
            return rarity.contains('classified');
          case RarityFilter.restricted:
            return rarity.contains('restricted');
          case RarityFilter.milSpec:
            return rarity.contains('mil-spec');
          default:
            return true;
        }
      }).toList();
    }

    // Сортування
    switch (_sortBy) {
      case SortBy.priceDesc:
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortBy.priceAsc:
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortBy.newest:
        items.sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
        break;
      case SortBy.oldest:
        items.sort((a, b) => a.acquiredAt.compareTo(b.acquiredAt));
        break;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _filteredAndSortedItems;
    final itemCount = displayedItems.length;
    final totalValue = displayedItems.fold(0.0, (sum, item) => sum + item.price);

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 10;
    } else if (screenWidth > 900) {
      crossAxisCount = 6;
    } else if (screenWidth > 600) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 2;
    }

    return Column(
      children: [
        _InventoryHeader(
          totalValue: totalValue,
          itemCount: itemCount,
          originalCount: widget.items.length,
        ),

        // Фільтри
        _FiltersBar(
          sortBy: _sortBy,
          rarityFilter: _rarityFilter,
          onSortChanged: (value) => setState(() => _sortBy = value),
          onRarityChanged: (value) => setState(() => _rarityFilter = value),
        ),

        Expanded(
          child: displayedItems.isEmpty
              ? const Center(
            child: Text(
              'Немає предметів з такими фільтрами',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final item = displayedItems[index];
              return _InventoryItemCard(
                item: item,
                onSell: () {
                  BalanceService.addMoney(item.price);
                  item.delete();
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Продано ${item.name} за \$${item.price.toStringAsFixed(2)}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final SortBy sortBy;
  final RarityFilter rarityFilter;
  final ValueChanged<SortBy> onSortChanged;
  final ValueChanged<RarityFilter> onRarityChanged;

  const _FiltersBar({
    required this.sortBy,
    required this.rarityFilter,
    required this.onSortChanged,
    required this.onRarityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Сортування
          const Icon(Icons.sort, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<SortBy>(
              value: sortBy,
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              underline: Container(),
              items: const [
                DropdownMenuItem(value: SortBy.priceDesc, child: Text('Ціна: спадання')),
                DropdownMenuItem(value: SortBy.priceAsc, child: Text('Ціна: зростання')),
                DropdownMenuItem(value: SortBy.newest, child: Text('Новіші спочатку')),
                DropdownMenuItem(value: SortBy.oldest, child: Text('Старіші спочатку')),
              ],
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),

          const SizedBox(width: 16),

          // Фільтр за рідкістю
          const Icon(Icons.filter_alt, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<RarityFilter>(
              value: rarityFilter,
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              underline: Container(),
              items: const [
                DropdownMenuItem(value: RarityFilter.all, child: Text('Всі рідкості')),
                DropdownMenuItem(
                  value: RarityFilter.covert,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFFEB4B4B), size: 12),
                      SizedBox(width: 8),
                      Text('Covert'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: RarityFilter.classified,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFFD32CE6), size: 12),
                      SizedBox(width: 8),
                      Text('Classified'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: RarityFilter.restricted,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF8847FF), size: 12),
                      SizedBox(width: 8),
                      Text('Restricted'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: RarityFilter.milSpec,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF4B69FF), size: 12),
                      SizedBox(width: 8),
                      Text('Mil-Spec'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) onRarityChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  final int itemCount;
  final int originalCount;
  final double totalValue;

  const _InventoryHeader({
    required this.itemCount,
    required this.originalCount,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(
            color: Colors.green.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                itemCount == originalCount
                    ? 'Предметів: $itemCount'
                    : 'Показано: $itemCount з $originalCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.green, size: 20),
              Text(
                '\$${totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onSell;

  const _InventoryItemCard({
    required this.item,
    required this.onSell,
  });

  Color _getRarityColor(String rarity) {
    final rarityLower = rarity.toLowerCase();
    if (rarityLower.contains('covert') || rarityLower.contains('extraordinary')) {
      return const Color(0xFFEB4B4B);
    }
    if (rarityLower.contains('classified')) {
      return const Color(0xFFD32CE6);
    }
    if (rarityLower.contains('restricted')) {
      return const Color(0xFF8847FF);
    }
    return const Color(0xFF4B69FF);
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(item.rarity);

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: rarityColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[900]!,
                    rarityColor.withOpacity(0.2),
                  ],
                ),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image_not_supported, color: rarityColor, size: 40);
                },
              )
                  : Icon(Icons.inventory, color: rarityColor, size: 40),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: onSell,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'ПРОДАТИ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
