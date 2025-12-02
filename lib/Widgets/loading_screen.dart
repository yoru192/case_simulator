import 'package:flutter/material.dart';
import 'package:case_simulator/services/api_service.dart';
import 'package:case_simulator/Pages/game_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _loadingMessage = 'Ініціалізація...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loadingMessage = 'Завантаження кейсів з API...';
      });

      await ApiService.loadCasesFromAPI();

      setState(() {
        _loadingMessage = 'Готово!';
      });

      // Невелика затримка щоб побачити "Готово!"
      await Future.delayed(const Duration(milliseconds: 500));

      // Переходимо на головний екран
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GamePage()),
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _loadingMessage = 'Помилка завантаження: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип або іконка
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.archive,
                size: 80,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 40),

            // Назва додатку
            const Text(
              'CS:GO Case Simulator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 60),

            // Індикатор завантаження або помилка
            if (!_hasError) ...[
              const CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade300,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _loadingMessage = 'Повторна спроба...';
                  });
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Спробувати знову'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
