import 'package:flutter/material.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/widgets/case_opening_screen.dart';
import 'package:case_simulator/services/balance_service.dart';
import 'package:case_simulator/widgets/balance_widget.dart';
import 'package:case_simulator/Services/api_service.dart'; // 👈 ДОДАЙТЕ

class CaseDetailsScreen extends StatefulWidget {
  final CaseModel caseModel;

  const CaseDetailsScreen({
    super.key,
    required this.caseModel,
  });

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    print('Items in case "${widget.caseModel.name}":');
    for (final item in widget.caseModel.items) {
      print('- ${item.name} [${item.rarity}]');
    }

    // 🎯 ОТРИМУЄМО АКТУАЛЬНУ ЦІНУ (ДЛЯ RECOIL ДИНАМІЧНУ)
    final actualPrice = _getActualPrice();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(widget.caseModel.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: BalanceWidget()),
          ),
        ],
      ),
      body: Column(
        children: [
          CaseHeader(caseModel: widget.caseModel, actualPrice: actualPrice), // 👈 ПЕРЕДАЄМО АКТУАЛЬНУ ЦІНУ
          // Open Case Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: () => _openCase(actualPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actualPrice > 0
                        ? 'OPEN CASE - \$${actualPrice.toStringAsFixed(2)}'
                        : 'OPEN CASE - FREE',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 🎯 ПОКАЗАТИ ЗАЛИШОК ДЛЯ RECOIL
                  if (widget.caseModel.name.toLowerCase().contains('recoil'))
                    Text(
                      'Безкоштовних відкриттів: ${ApiService.getRecoilFreeOpensRemaining()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${widget.caseModel.items.length} предметів',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ItemsList(items: widget.caseModel.items),
          ),
        ],
      ),
    );
  }

  // 🎯 МЕТОД ДЛЯ ОТРИМАННЯ АКТУАЛЬНОЇ ЦІНИ
  double _getActualPrice() {
    if (widget.caseModel.name.toLowerCase().contains('recoil')) {
      return ApiService.getRecoilCasePrice();
    }
    return widget.caseModel.price;
  }

  // 🎯 МЕТОД ДЛЯ ВІДКРИТТЯ КЕЙСУ
  void _openCase(double actualPrice) {
    final balance = BalanceService.getBalance();

    // Перевірка балансу
    if (balance < actualPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Недостатньо коштів! Потрібно \$${actualPrice.toStringAsFixed(2)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Віднімаємо гроші ТІЛЬКИ якщо ціна > 0
    if (actualPrice > 0) {
      BalanceService.removeMoney(actualPrice);
      print('💰 Списано з балансу: \$${actualPrice.toStringAsFixed(2)}');
    } else {
      print('🎁 Безкоштовне відкриття Recoil case!');
    }

    // Відкриваємо кейс
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaseOpeningScreen(caseModel: widget.caseModel),
      ),
    ).then((result) {
      setState(() {}); // Оновлюємо UI після повернення
    });
  }
}

// 🎯 ОНОВЛЕНИЙ CaseHeader З АКТУАЛЬНОЮ ЦІНОЮ
class CaseHeader extends StatelessWidget {
  final CaseModel caseModel;
  final double actualPrice; // 👈 ДОДАНО

  const CaseHeader({
    required this.caseModel,
    required this.actualPrice, // 👈 ДОДАНО
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: caseModel.imageUrl.isNotEmpty
                ? Image.network(
              caseModel.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.archive, size: 80, color: Colors.green);
              },
            )
                : const Icon(Icons.archive, size: 80, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            caseModel.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Text(
              actualPrice > 0 ? '\$${actualPrice.toStringAsFixed(2)}' : 'FREE', // 👈 ВИКОРИСТОВУЄМО АКТУАЛЬНУ ЦІНУ
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemsList extends StatelessWidget {
  final List<CaseItem> items;

  const ItemsList({required this.items});

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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final rarityColor = _getRarityColor(item.rarity);

        return Container(

          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rarityColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image_not_supported, color: rarityColor);
                },
              )
                  : Icon(Icons.inventory, color: rarityColor),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              item.rarity,
              style: TextStyle(
                fontSize: 12,
                color: rarityColor,
              ),
            ),
          ),
        );
      },

    );

  }
}
