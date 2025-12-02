import 'dart:convert';
import 'package:hive/hive.dart';

part 'case.g.dart';

@HiveType(typeId: 1)
class CaseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String imageUrl;

  @HiveField(3)
  double price;

  @HiveField(4)
  String rarity;

  @HiveField(5)
  List<String> itemsJson;

  CaseModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rarity,
    required this.itemsJson,
  });

  List<CaseItem> get items {
    return itemsJson.map((jsonStr) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return CaseItem.fromJson(json);
      } catch (e) {
        print('Error parsing item: $e');
        return CaseItem(
          id: '',
          name: 'Unknown',
          rarity: 'Unknown',
          rarityColor: '#4B69FF',
          imageUrl: '',
          paintIndex: 0,
        );
      }
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'rarity': rarity,
      'itemsJson': itemsJson,
    };
  }

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      rarity: json['rarity'] as String,
      itemsJson: List<String>.from(json['itemsJson'] as List),
    );
  }
}

class CaseItem {
  final String id;
  final String name;
  final String rarity;
  final String rarityColor;
  final String imageUrl;
  final int paintIndex;

  CaseItem({
    required this.id,
    required this.name,
    required this.rarity,
    required this.rarityColor,
    required this.imageUrl,
    required this.paintIndex,
  });

  factory CaseItem.fromJson(Map<String, dynamic> json) {
    return CaseItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rarity: json['rarity']?['name'] as String? ?? 'Unknown',
      rarityColor: json['rarity']?['color'] as String? ?? '#4B69FF',
      imageUrl: json['image'] as String? ?? '',
      paintIndex: json['paint_index'] as int? ?? 0,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rarity': {
        'name': rarity,
        'color': rarityColor,
      },
      'image': imageUrl,
      'paint_index': paintIndex,
    };
  }
}
