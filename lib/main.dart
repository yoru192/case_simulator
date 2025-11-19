import 'package:case_simulator/Pages/game_page.dart';
import 'package:case_simulator/Models/item.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ініціалізація Hive
  await Hive.initFlutter();

  // Реєстрація адаптерів
  Hive.registerAdapter(ItemModelAdapter());
  Hive.registerAdapter(CaseModelAdapter());

  // Відкриття боксів
  await Hive.openBox<ItemModel>('inventory');
  await Hive.openBox<CaseModel>('cases');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Case Simulator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GamePage(),
    );
  }
}
