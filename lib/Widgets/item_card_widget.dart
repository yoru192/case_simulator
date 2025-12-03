import 'package:flutter/material.dart';
import 'package:case_simulator/Models/item.dart';

class ItemCardWidget extends StatelessWidget {
  final String itemName;
  final String? imageUrl;
  final String rarity;
  final double? price;
  final VoidCallback? onTap;
  final bool showPrice;

  const ItemCardWidget({
    super.key,
    required this.itemName,
    this.imageUrl,
    required this.rarity,
    this.price,
    this.onTap,
    this.showPrice = true,
  });

  // Альтернативний конструктор для ItemModel
  factory ItemCardWidget.fromItemModel(
      ItemModel item, {
        VoidCallback? onTap,
        bool showPrice = true,
      }) {
    return ItemCardWidget(
      itemName: item.name,
      imageUrl: item.imageUrl,
      rarity: item.rarity,
      price: item.price,
      onTap: onTap,
      showPrice: showPrice,
    );
  }

  bool _isKnife(String rarity, String name) {
    final r = rarity.toLowerCase();
    final n = name.toLowerCase();
    return r.contains('★') ||
        r.contains('knife') ||
        r.contains('extraordinary') ||
        n.contains('★');
  }

  Color _getRarityColor(String rarity, String name) {
    if (_isKnife(rarity, name)) {
      return const Color(0xFFFFD700); // Золотий для ножів
    }

    switch (rarity.toLowerCase()) {
      case 'covert':
      case 'extraordinary':
        return const Color(0xFFEB4B4B);
      case 'classified':
        return const Color(0xFFD32CE6);
      case 'restricted':
        return const Color(0xFF8847FF);
      case 'mil-spec grade':
      case 'mil-spec':
        return const Color(0xFF4B69FF);
      case 'industrial grade':
        return const Color(0xFF5E98D9);
      case 'consumer grade':
        return const Color(0xFFB0C3D9);
      default:
        return const Color(0xFF4B69FF);
    }
  }


  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(rarity,itemName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D2D2D),
              rarityColor.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: rarityColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Зображення предмету
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 40,
                    );
                  },
                )
                    : const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            ),

            // Смуга рідкості
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rarityColor.withOpacity(0.5),
                    rarityColor,
                    rarityColor.withOpacity(0.5),
                  ],
                ),
              ),
            ),

            // Назва та ціна
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Назва
                  Text(
                    itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  if (showPrice && price != null) ...[
                    const SizedBox(height: 4),
                    // Ціна
                    Text(
                      '\$${price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
