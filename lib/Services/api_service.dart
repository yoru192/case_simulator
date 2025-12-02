import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:case_simulator/Models/case.dart';

class ApiService {
  static const String _apiUrl =
      'https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/crates.json';

  static Future loadCasesFromAPI() async {
    final casesBox = Hive.box<CaseModel>('cases');
    // Перевірка чи вже завантажені дані
    if (casesBox.isNotEmpty) {
      print('Кейси вже завантажені: ${casesBox.length}');
      return;
    }

    try {
      print('Завантаження кейсів з API...');
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List casesData = jsonDecode(response.body);

        // Фільтруємо тільки кейси (не подарунки)
        final filteredCases = casesData.where((caseJson) {
          return caseJson['type'] == 'Case' &&
              (caseJson['contains'] as List).isNotEmpty;
        }).toList();

        print('Знайдено кейсів: ${filteredCases.length}');

        // Парсимо та зберігаємо кожен кейс
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
      // Безпечна обробка paint_index
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

    // 🎯 ДИНАМІЧНА ЦІНА НА ОСНОВІ НАЗВИ КЕЙСУ
    final price = _calculateCasePrice(caseName);

    print('Парсинг кейсу: $caseName (предметів: ${itemsJsonStrings.length}, ціна: \$$price)');

    return CaseModel(
      id: json['id'] as String,
      name: caseName,
      imageUrl: imageUrl,
      price: price,
      rarity: json['rarity']?['name'] as String? ?? 'Base Grade',
      itemsJson: itemsJsonStrings,
    );
  }

  // 🎯 РОЗРАХУНОК ЦІНИ НА ОСНОВІ РЕАЛЬНИХ ЦІН STEAM MARKET
  static double _calculateCasePrice(String caseName) {
    final lowerName = caseName.toLowerCase();

    // === БЕЗКОШТОВНІ/ДУЖЕ ДЕШЕВІ (2013-2014) ===
    if (lowerName.contains('weapon case') && !lowerName.contains('2') && !lowerName.contains('3')) {
      return 98.0; // CS:GO Weapon Case - $98 (колекційний)
    }

    if (lowerName.contains('weapon case 2')) {
      return 9.70; // CS:GO Weapon Case 2 - $9.71
    }

    if (lowerName.contains('weapon case 3')) {
      return 5.60; // CS:GO Weapon Case 3 - $5.62
    }

    if (lowerName.contains('esports 2013 case')) {
      return 40.0; // eSports 2013 Case - $40
    }

    if (lowerName.contains('esports 2013 winter')) {
      return 7.80; // eSports 2013 Winter - $7.77
    }

    if (lowerName.contains('esports 2014 summer')) {
      return 6.90; // eSports 2014 Summer - $6.93
    }

    if (lowerName.contains('winter offensive')) {
      return 4.80; // Winter Offensive - $4.80
    }

    if (lowerName.contains('operation bravo')) {
      return 36.0; // Operation Bravo - $36.36
    }

    // === СТАРІ ОПЕРАЦІЙНІ (2014-2015) ===
    if (lowerName.contains('phoenix')) {
      return 2.20; // Operation Phoenix - $2.23
    }

    if (lowerName.contains('huntsman')) {
      return 8.20; // Huntsman - $8.17
    }

    if (lowerName.contains('breakout')) {
      return 8.40; // Operation Breakout - $8.37
    }

    if (lowerName.contains('vanguard')) {
      return 3.40; // Operation Vanguard - $3.42
    }

    // === CHROMA СЕРІЯ (2015-2016) ===
    if (lowerName.contains('chroma 3')) {
      return 2.90; // Chroma 3 - $2.89
    }

    if (lowerName.contains('chroma 2')) {
      return 3.10; // Chroma 2 - $3.13
    }

    if (lowerName.contains('chroma') && !lowerName.contains('2') && !lowerName.contains('3')) {
      return 4.20; // Chroma - $4.23
    }

    // === СЕРЕДНІ КЕЙСИ (2015-2016) ===
    if (lowerName.contains('falchion')) {
      return 0.70; // Falchion - $0.68
    }

    if (lowerName.contains('shadow')) {
      return 0.70; // Shadow - $0.70
    }

    if (lowerName.contains('revolver')) {
      return 1.40; // Revolver - $1.41
    }

    if (lowerName.contains('wildfire')) {
      return 2.60; // Operation Wildfire - $2.59
    }

    // === GAMMA СЕРІЯ (2016) ===
    if (lowerName.contains('gamma 2')) {
      return 3.50; // Gamma 2 - $3.51
    }

    if (lowerName.contains('gamma')) {
      return 3.50; // Gamma - $3.47
    }

    // === GLOVE & SPECTRUM (2016-2017) ===
    if (lowerName.contains('glove')) {
      return 15.60; // Glove - $15.56
    }

    if (lowerName.contains('spectrum 2')) {
      return 2.40; // Spectrum 2 - $2.42
    }

    if (lowerName.contains('spectrum')) {
      return 3.20; // Spectrum - $3.20
    }

    // === ОПЕРАЦІЙНІ (2017-2018) ===
    if (lowerName.contains('hydra')) {
      return 31.0; // Operation Hydra - $31.02
    }

    if (lowerName.contains('clutch')) {
      return 0.35; // Clutch - $0.35
    }

    if (lowerName.contains('horizon')) {
      return 1.10; // Horizon - $1.11
    }

    // === НОВІ КЕЙСИ (2019-2020) ===
    if (lowerName.contains('danger zone')) {
      return 0.90; // Danger Zone - $0.91
    }

    if (lowerName.contains('prisma 2')) {
      return 1.00; // Prisma 2 - $0.98
    }

    if (lowerName.contains('prisma')) {
      return 0.95; // Prisma - $0.94
    }

    if (lowerName.contains('cs20')) {
      return 0.45; // CS20 - $0.45
    }

    if (lowerName.contains('shattered web')) {
      return 4.90; // Shattered Web - $4.87
    }

    // === ОПЕРАЦІЙНІ (2020-2021) ===
    if (lowerName.contains('fracture')) {
      return 0.35; // Fracture - $0.35
    }

    if (lowerName.contains('broken fang')) {
      return 6.20; // Operation Broken Fang - $6.24
    }

    if (lowerName.contains('snakebite')) {
      return 0.60; // Snakebite - $0.60
    }

    if (lowerName.contains('riptide')) {
      return 11.20; // Operation Riptide - $11.17
    }

    // === НОВІ CS2 КЕЙСИ (2022-2025) ===
    if (lowerName.contains('dreams') || lowerName.contains('nightmares')) {
      return 1.00; // Dreams & Nightmares - $1.01
    }

    if (lowerName.contains('recoil')) {
      return 0; // Recoil - $0
    }

    if (lowerName.contains('revolution')) {
      return 0.46; // Revolution - $0.46
    }

    if (lowerName.contains('kilowatt')) {
      return 0.45; // Kilowatt - $0.45
    }

    if (lowerName.contains('gallery')) {
      return 1.07; // Gallery - $1.07
    }

    if (lowerName.contains('fever')) {
      return 1.00; // Fever - $1.00
    }

    // За замовчуванням
    return 0.50;
  }


  // Метод для очистки та перезавантаження даних
  static Future reloadCases() async {
    final casesBox = Hive.box<CaseModel>('cases');
    await casesBox.clear();
    print('База очищена');
    await loadCasesFromAPI();
  }
}
