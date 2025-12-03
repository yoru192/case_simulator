import 'package:case_simulator/Models/item.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/Models/rank.dart';
import 'package:case_simulator/Models/user.dart';
import 'package:case_simulator/Pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/quest.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ItemModelAdapter());
  Hive.registerAdapter(CaseModelAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(RankModelAdapter());
  Hive.registerAdapter(QuestModelAdapter());
  Hive.registerAdapter(QuestTypeAdapter());
  Hive.registerAdapter(QuestStatusAdapter());


  await Hive.openBox<ItemModel>('inventory');
  await Hive.openBox<CaseModel>('cases');
  await Hive.openBox('users');
  await Hive.openBox<QuestModel>('quests');
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Case Simulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}