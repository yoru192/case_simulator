import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/services/auth_service.dart';

class ApiService {
  static const String _apiUrl =
      'https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/crates.json';

  // 🎯 ГЕНЕРАЦІЯ КЛЮЧА ДЛЯ КОНКРЕТНОГО КОРИСТУВАЧА
  static String _getRecoilCounterKey() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 'recoil_free_opens_guest';
    return 'recoil_free_opens_${user.id}';
  }

  static Future loadCasesFromAPI() async {
    final casesBox = Hive.box<CaseModel>('cases'); // 👈 ВИПРАВЛЕНО

    if (casesBox.isNotEmpty) {
      print('Кейси вже завантажені: ${casesBox.length}');
      return;
    }

    try {
      print('Завантаження кейсів з API...');
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List casesData = jsonDecode(response.body);

        final filteredCases = casesData.where((caseJson) {
          return caseJson['type'] == 'Case' &&
              (caseJson['contains'] as List).isNotEmpty;
        }).toList();

        print('Знайдено кейсів: ${filteredCases.length}');

        for (var caseJson in filteredCases) {
          final caseModel = _parseCaseFromAPI(caseJson);
          await casesBox.put(caseModel.id, caseModel);
        }

        print('Кейси успішно завантажені!');
      } else {
        print('Помилка завантаження: ${response.statusCode}');
      }
    } catch (e) {
      print('Помилка при завантаженні кейсів: $e');
    }
  }

  static CaseModel _parseCaseFromAPI(Map json) {
    final List containsItems = json['contains'] ?? [];
    final List<String> itemsJsonStrings = containsItems.map((item) {

      dynamic paintIndexValue = item['paint_index'];
      int paintIndex = 0;

      if (paintIndexValue != null) {
        if (paintIndexValue is int) {
          paintIndex = paintIndexValue;
        } else if (paintIndexValue is String) {
          paintIndex = int.tryParse(paintIndexValue) ?? 0;
        }
      }

      final caseItem = {
        'id': item['id'] ?? '',
        'name': item['name'] ?? '',
        'rarity': {
          'name': item['rarity']?['name'] ?? 'Unknown',
          'color': item['rarity']?['color'] ?? '#4B69FF',
        },
        'image': item['image'] ?? '',
        'paint_index': paintIndex,
      };
      return jsonEncode(caseItem);
    }).toList();

    final imageUrl = json['image'] as String? ?? '';
    final caseName = json['name'] as String;

    final price = _calculateCasePrice(caseName);

    print('Парсинг кейсу: $caseName (предметів: ${itemsJsonStrings.length}, ціна: \$$price)');

    final hasKnife = itemsJsonStrings.any((s) => s.contains('★') || s.toLowerCase().contains('knife'));
    print('Case $caseName hasKnife: $hasKnife, items: ${itemsJsonStrings.length}');

    return CaseModel(
      id: json['id'] as String,
      name: caseName,
      imageUrl: imageUrl,
      price: price,
      rarity: json['rarity']?['name'] as String? ?? 'Base Grade',
      itemsJson: itemsJsonStrings,
    );
  }

  // 🎯 ОТРИМАННЯ ПОТОЧНОЇ ЦІНИ RECOIL (БЕЗ ІНКРЕМЕНТУ)
  static double getRecoilCasePrice() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 0.22;

    final settingsBox = Hive.box('settings');
    final key = _getRecoilCounterKey();
    final counter = settingsBox.get(key, defaultValue: 0) as int;

    if (counter < 10) {
      return 0.0;
    } else {
      return 0.22;
    }
  }

  // 🎯 ІНКРЕМЕНТ ЛІЧИЛЬНИКА ПРИ ВІДКРИТТІ КЕЙСУ
  static Future<void> incrementRecoilCounter() async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      print('⚠️ Користувач не авторизований, лічильник не оновлюється');
      return;
    }

    final settingsBox = Hive.box('settings');
    final key = _getRecoilCounterKey();
    final counter = settingsBox.get(key, defaultValue: 0) as int;
    await settingsBox.put(key, counter + 1);

    print('🎮 Recoil відкрито користувачем ${user.nickname}: ${counter + 1} разів');
  }

  // 🎯 ОТРИМАННЯ КІЛЬКОСТІ ВИКОРИСТАНИХ БЕЗКОШТОВНИХ ВІДКРИТТІВ
  static int getRecoilFreeOpensUsed() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 10;

    final settingsBox = Hive.box('settings');
    final key = _getRecoilCounterKey();
    return settingsBox.get(key, defaultValue: 0) as int;
  }

  // 🎯 ОТРИМАННЯ КІЛЬКОСТІ ЗАЛИШКОВИХ БЕЗКОШТОВНИХ ВІДКРИТТІВ
  static int getRecoilFreeOpensRemaining() {
    final used = getRecoilFreeOpensUsed();
    return used < 10 ? 10 - used : 0;
  }

  // 🎯 СКИДАННЯ ЛІЧИЛЬНИКА (для тестування або нових подій)
  static Future<void> resetRecoilCounter() async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      print('⚠️ Користувач не авторизований');
      return;
    }

    final settingsBox = Hive.box('settings');
    final key = _getRecoilCounterKey();
    await settingsBox.put(key, 0);
    print('🔄 Лічильник Recoil скинуто для користувача ${user.nickname}');
  }

  // 🎯 ОТРИМАТИ ІНФОРМАЦІЮ ПРО RECOIL ДЛЯ ПОТОЧНОГО КОРИСТУВАЧА
  static Map<String, dynamic> getRecoilInfo() {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      return {
        'isAuthorized': false,
        'used': 10,
        'remaining': 0,
        'currentPrice': 0.22,
      };
    }

    final used = getRecoilFreeOpensUsed();
    final remaining = getRecoilFreeOpensRemaining();
    final price = getRecoilCasePrice();

    return {
      'isAuthorized': true,
      'userId': user.id,
      'username': user.nickname,
      'used': used,
      'remaining': remaining,
      'currentPrice': price,
    };
  }

  static double _calculateCasePrice(String caseName) {
    final lowerName = caseName.toLowerCase();

    if (lowerName.contains('weapon case') && !lowerName.contains('2') && !lowerName.contains('3')) {
      return 98.0;
    }

    if (lowerName.contains('weapon case 2')) {
      return 9.70;
    }

    if (lowerName.contains('weapon case 3')) {
      return 5.60;
    }

    if (lowerName.contains('esports 2013 case')) {
      return 40.0;
    }

    if (lowerName.contains('esports 2013 winter')) {
      return 7.80;
    }

    if (lowerName.contains('esports 2014 summer')) {
      return 6.90;
    }

    if (lowerName.contains('winter offensive')) {
      return 4.80;
    }

    if (lowerName.contains('operation bravo')) {
      return 36.0;
    }

    if (lowerName.contains('phoenix')) {
      return 2.20;
    }

    if (lowerName.contains('huntsman')) {
      return 8.20;
    }

    if (lowerName.contains('breakout')) {
      return 8.40;
    }

    if (lowerName.contains('vanguard')) {
      return 3.40;
    }

    if (lowerName.contains('chroma 3')) {
      return 2.90;
    }

    if (lowerName.contains('chroma 2')) {
      return 3.10;
    }

    if (lowerName.contains('chroma') && !lowerName.contains('2') && !lowerName.contains('3')) {
      return 4.20;
    }

    if (lowerName.contains('falchion')) {
      return 0.70;
    }

    if (lowerName.contains('shadow')) {
      return 0.70;
    }

    if (lowerName.contains('revolver')) {
      return 1.40;
    }

    if (lowerName.contains('wildfire')) {
      return 2.60;
    }

    if (lowerName.contains('gamma 2')) {
      return 3.50;
    }

    if (lowerName.contains('gamma')) {
      return 3.50;
    }

    if (lowerName.contains('glove')) {
      return 15.60;
    }

    if (lowerName.contains('spectrum 2')) {
      return 2.40;
    }

    if (lowerName.contains('spectrum')) {
      return 3.20;
    }

    if (lowerName.contains('hydra')) {
      return 31.0;
    }

    if (lowerName.contains('clutch')) {
      return 0.35;
    }

    if (lowerName.contains('horizon')) {
      return 1.10;
    }

    if (lowerName.contains('danger zone')) {
      return 0.90;
    }

    if (lowerName.contains('prisma 2')) {
      return 1.00;
    }

    if (lowerName.contains('prisma')) {
      return 0.95;
    }

    if (lowerName.contains('cs20')) {
      return 0.45;
    }

    if (lowerName.contains('shattered web')) {
      return 4.90;
    }

    if (lowerName.contains('fracture')) {
      return 0.35;
    }

    if (lowerName.contains('broken fang')) {
      return 6.20;
    }

    if (lowerName.contains('snakebite')) {
      return 0.60;
    }

    if (lowerName.contains('riptide')) {
      return 11.20;
    }

    if (lowerName.contains('dreams') || lowerName.contains('nightmares')) {
      return 1.00;
    }

    // 🎯 RECOIL CASE - ДИНАМІЧНА ЦІНА
    if (lowerName.contains('recoil')) {
      return getRecoilCasePrice();
    }

    if (lowerName.contains('revolution')) {
      return 0.46;
    }

    if (lowerName.contains('kilowatt')) {
      return 0.45;
    }

    if (lowerName.contains('gallery')) {
      return 1.07;
    }

    if (lowerName.contains('fever')) {
      return 1.00;
    }

    return 0.50;
  }

  static Future reloadCases() async {
    final casesBox = Hive.box<CaseModel>('cases'); // 👈 ВИПРАВЛЕНО
    await casesBox.clear();
    print('База очищена');
    await loadCasesFromAPI();
  }
}
