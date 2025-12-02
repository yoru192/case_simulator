import 'dart:math';
import 'package:hive/hive.dart';
import 'package:case_simulator/services/auth_service.dart';
import 'package:case_simulator/Models/rank.dart';

class XPService {
  static String _getXPKey() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 'xp_guest';
    return 'xp_${user.id}';
  }

  // Отримати поточний XP
  static int getXP() {
    final box = Hive.box('settings');
    return box.get(_getXPKey(), defaultValue: 0) as int;
  }

  // Встановити XP
  static void setXP(int xp) {
    final box = Hive.box('settings');
    box.put(_getXPKey(), xp);
  }

  // Додати XP
  static void addXP(int amount) {
    final currentXP = getXP();
    setXP(currentXP + amount);
  }

  // Отримати поточний ранг
  static RankModel getCurrentRank() {
    final xp = getXP();

    // Знаходимо найвищий досягнутий ранг
    RankModel currentRank = RankData.ranks.first;
    for (var rank in RankData.ranks) {
      if (xp >= rank.requiredXP) {
        currentRank = rank;
      } else {
        break;
      }
    }

    return currentRank;
  }

  // Отримати наступний ранг
  static RankModel? getNextRank() {
    final currentRank = getCurrentRank();

    if (currentRank.level >= RankData.ranks.length - 1) {
      return null; // Максимальний ранг
    }

    return RankData.ranks[currentRank.level + 1];
  }

  // Прогрес до наступного рангу (0.0 - 1.0)
  static double getProgressToNextRank() {
    final xp = getXP();
    final currentRank = getCurrentRank();
    final nextRank = getNextRank();

    if (nextRank == null) {
      return 1.0; // Максимальний ранг
    }

    final xpInCurrentRank = xp - currentRank.requiredXP;
    final xpNeeded = nextRank.requiredXP - currentRank.requiredXP;

    return (xpInCurrentRank / xpNeeded).clamp(0.0, 1.0);
  }

  // Скільки XP потрібно до наступного рангу
  static int getXPToNextRank() {
    final xp = getXP();
    final nextRank = getNextRank();

    if (nextRank == null) return 0;

    return (nextRank.requiredXP - xp).clamp(0, 999999);
  }

  // Нарахування XP за відкриття кейсу (залежить від рідкості випавшого предмету)
  static int calculateXPForCaseOpening(String rarity) {
    final random = Random();
    final rarityLower = rarity.toLowerCase();

    if (rarityLower.contains('covert') || rarityLower.contains('extraordinary')) {
      return 10 + random.nextInt(4); // 10-13 XP
    }

    if (rarityLower.contains('classified')) {
      return 7 + random.nextInt(3); // 7-9 XP
    }

    if (rarityLower.contains('restricted')) {
      return 5 + random.nextInt(2); // 5-6 XP
    }

    return 3 + random.nextInt(3); // 3-5 XP для Mil-Spec
  }
}
