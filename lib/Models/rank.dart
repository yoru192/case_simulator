import 'package:hive/hive.dart';

part 'rank.g.dart';

@HiveType(typeId: 3)
class RankModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int requiredXP;

  @HiveField(2)
  String iconPath; // Шлях до іконки або emoji

  @HiveField(3)
  int level; // 0-17 (18 рангів)

  RankModel({
    required this.name,
    required this.requiredXP,
    required this.iconPath,
    required this.level,
  });
}

// Статичні дані рангів
class RankData {
  static final List<RankModel> ranks = [
    RankModel(name: 'Silver 1', requiredXP: 0, iconPath: '🥈', level: 0),
    RankModel(name: 'Silver 2', requiredXP: 50, iconPath: '🥈', level: 1),
    RankModel(name: 'Silver 3', requiredXP: 200, iconPath: '🥈', level: 2),
    RankModel(name: 'Silver 4', requiredXP: 500, iconPath: '🥈', level: 3),
    RankModel(name: 'Silver Elite', requiredXP: 625, iconPath: '🥈', level: 4),
    RankModel(name: 'Silver Elite Master', requiredXP: 750, iconPath: '🥈', level: 5),
    RankModel(name: 'Gold Nova 1', requiredXP: 875, iconPath: '⭐', level: 6),
    RankModel(name: 'Gold Nova 2', requiredXP: 1000, iconPath: '⭐', level: 7),
    RankModel(name: 'Gold Nova 3', requiredXP: 1125, iconPath: '⭐', level: 8),
    RankModel(name: 'Gold Nova Master', requiredXP: 1250, iconPath: '⭐', level: 9),
    RankModel(name: 'Master Guardian 1', requiredXP: 1375, iconPath: '🛡️', level: 10),
    RankModel(name: 'Master Guardian 2', requiredXP: 1500, iconPath: '🛡️', level: 11),
    RankModel(name: 'Master Guardian Elite', requiredXP: 1675, iconPath: '🛡️', level: 12),
    RankModel(name: 'Distinguished Master Guardian', requiredXP: 1800, iconPath: '🎖️', level: 13),
    RankModel(name: 'Legendary Eagle', requiredXP: 1925, iconPath: '🦅', level: 14),
    RankModel(name: 'Legendary Eagle Master', requiredXP: 2050, iconPath: '🦅', level: 15),
    RankModel(name: 'Supreme Master First Class', requiredXP: 2175, iconPath: '👑', level: 16),
    RankModel(name: 'The Global Elite', requiredXP: 2300, iconPath: '💎', level: 17),
  ];
}
