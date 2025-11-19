import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/item.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/widgets/home_screen.dart';
import 'package:case_simulator/widgets/cases_screen.dart';
import 'package:case_simulator/widgets/inventory_screen.dart';
import 'package:case_simulator/widgets/navigation_drawer.dart';
import 'package:case_simulator/widgets/navigation_bar.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = -1;

  late Box<CaseModel> casesBox;
  late Box<ItemModel> inventoryBox;

  final List<String> _menuItems = ['Cases', 'Inventory'];

  @override
  void initState() {
    super.initState();
    casesBox = Hive.box<CaseModel>('cases');
    inventoryBox = Hive.box<ItemModel>('inventory');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(isLargeScreen),
        drawer: isLargeScreen ? null : _buildDrawer(),
        body: _getBody(),
      ),
    );
  }

  AppBar _buildAppBar(bool isLargeScreen) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Case Simulator",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isLargeScreen)
              Expanded(
                child: AppNavigationBar(
                  menuItems: _menuItems,
                  onItemTap: _handleNavigationTap,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return AppNavigationDrawer(
      menuItems: _menuItems,
      onItemTap: _handleNavigationTap,
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case -1:
        return HomeScreen(onCasesTap: () => _handleNavigationTap(0));
      case 0:
        return CasesScreen(
          casesBox: casesBox,
          onAddSampleCases: _addSampleCases,
        );
      case 1:
        return InventoryScreen(inventoryBox: inventoryBox);
      default:
        return HomeScreen(onCasesTap: () => _handleNavigationTap(0));
    }
  }

  void _handleNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addSampleCases() async {
    final cases = [
      CaseModel(
        id: '1',
        name: 'Chroma Case',
        imageUrl: '',
        price: 2.50,
        rarity: 'Rare',
        items: ['item1', 'item2', 'item3'],
      ),
      CaseModel(
        id: '2',
        name: 'Gamma Case',
        imageUrl: '',
        price: 3.00,
        rarity: 'Epic',
        items: ['item4', 'item5'],
      ),
      CaseModel(
        id: '3',
        name: 'Spectrum Case',
        imageUrl: '',
        price: 1.80,
        rarity: 'Rare',
        items: ['item6', 'item7', 'item8'],
      ),
    ];

    for (var caseItem in cases) {
      await casesBox.add(caseItem);
    }
  }
}
