import 'package:case_simulator/Widgets/balance_widget.dart';
import 'package:case_simulator/Widgets/rank_widget.dart';
import 'package:case_simulator/Pages/ranks_screen.dart'; // ← ДОДАЙ ЦЕЙ ІМПОРТ
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/item.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/widgets/cases_screen.dart';
import 'package:case_simulator/widgets/inventory_screen.dart';
import 'package:case_simulator/services/auth_service.dart';
import 'package:case_simulator/Pages/login_screen.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _currentIndex = 0;
  late final Box<ItemModel> _inventoryBox;
  late final Box<CaseModel> _casesBox;

  @override
  void initState() {
    super.initState();
    _inventoryBox = Hive.box<ItemModel>('inventory');
    _casesBox = Hive.box<CaseModel>('cases');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вихід'),
        content: const Text('Ви впевнені що хочете вийти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
  }

  // ← ДОДАЙ ЦЕЙ МЕТОД
  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return CasesScreen(casesBox: _casesBox, onAddSampleCases: () {});
      case 1:
        return InventoryScreen(inventoryBox: _inventoryBox);
      case 2:
        return const RanksScreen(); // ← Новий екран
      default:
        return CasesScreen(casesBox: _casesBox, onAddSampleCases: () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.getCurrentUser();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Case Simulator',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Нікнейм користувача
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.green, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      currentUser.nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: RankWidget(compact: true),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: BalanceWidget(),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Вийти',
            onPressed: _logout,
          ),
        ],
      ),
      body: _getScreen(), // ← ЗМІНИ ТУТ (було тернарний оператор)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF2D2D2D),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.archive),
            label: 'Cases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Ranks',
          ),
        ],
      ),
    );
  }
}
