import 'package:flutter/material.dart';
import 'package:case_simulator/services/auth_service.dart';
import 'package:case_simulator/Services/api_service.dart';
import 'package:case_simulator/Pages/login_screen.dart';
import 'package:case_simulator/Pages/game_page.dart';
import '../Services/quest_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  String _statusText = 'Завантаження...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Завантажуємо кейси
      setState(() => _statusText = 'Завантаження кейсів...');
      await ApiService.loadCasesFromAPI();
      await Future.delayed(const Duration(milliseconds: 500));

      // Перевіряємо авторизацію
      setState(() => _statusText = 'Перевірка авторизації...');
      final isLoggedIn = AuthService.isLoggedIn();

      // ✅ ПЕРЕВІРЯЄМО ТА СКИДАЄМО КВЕСТИ І RECOIL (ТІЛЬКИ ДЛЯ ЗАЛОГІНЕНИХ)
      if (isLoggedIn) {
        setState(() => _statusText = 'Оновлення квестів...');
        await QuestService.checkAndResetQuests();

        // ✅ ДОДАЙ ЦЕЙ РЯДОК - СКИДАННЯ RECOIL
        await ApiService.checkAndResetRecoilOpens();
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Навігація
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isLoggedIn ? const GamePage() : const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() => _statusText = 'Помилка завантаження: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _showRetryDialog();
      }
    }
  }


  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Помилка'),
        content: const Text('Не вдалося завантажити дані. Спробувати знову?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initialize();
            },
            child: const Text('Спробувати знову'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Іконка
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.casino,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 40),

              // Назва
              const Text(
                'CS:GO Case Simulator',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Індикатор завантаження
              const CircularProgressIndicator(
                color: Colors.green,
              ),
              const SizedBox(height: 20),

              // Статус
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}