import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String weapon;

  @HiveField(3)
  String skin;

  @HiveField(4)
  double price;

  @HiveField(5)
  String rarity;

  @HiveField(6)
  String imageUrl;

  @HiveField(7)
  DateTime acquiredAt;

  @HiveField(8)
  String userId; // ← ДОДАЙ ЦЕ ПОЛЕ

  ItemModel({
    required this.id,
    required this.name,
    required this.weapon,
    required this.skin,
    required this.price,
    required this.rarity,
    required this.imageUrl,
    required this.acquiredAt,
    required this.userId, // ← ДОДАЙ ЦЕ
  });
}
