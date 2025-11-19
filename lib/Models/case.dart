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
  List<String> items;

  CaseModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rarity,
    required this.items,
  });

  // Метод для конвертації у JSON (якщо потрібно для API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'rarity': rarity,
      'items': items,
    };
  }

  // Фабричний конструктор для створення з JSON
  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      rarity: json['rarity'] as String,
      items: List<String>.from(json['items'] as List),
    );
  }

  // Метод copyWith для створення копії з змінами
  CaseModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    String? rarity,
    List<String>? items,
  }) {
    return CaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      rarity: rarity ?? this.rarity,
      items: items ?? this.items,
    );
  }
}
