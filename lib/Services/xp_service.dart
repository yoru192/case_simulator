import 'package:hive/hive.dart';
import 'package:case_simulator/services/auth_service.dart';
import 'package:case_simulator/Models/rank.dart';

class XPService {
  // Отримати поточний XP
  static int getXP() {
    final user = AuthService.getCurrentUser();
    if (user == null) return 0;

    final settingsBox = Hive.box('settings');
    return settingsBox.get('xp_${user.id}', defaultValue: 0);
  }

  // Встановити XP
  static void setXP(int xp) {
    final user = AuthService.getCurrentUser();
    if (user == null) return;

    final settingsBox = Hive.box('settings');
    settingsBox.put('xp_${user.id}', xp);
  }

  // Додати XP
  static void addXP(int amount) {
    final currentXP = getXP();
    setXP(currentXP + amount);
  }

  // Отримати поточний ранг
  static RankModel getCurrentRank() {
    final xp = getXP();
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
      return null;
    }
    return RankData.ranks[currentRank.level + 1];
  }

  // Прогрес до наступного рангу (0.0 - 1.0)
  static double getProgressToNextRank() {
    final xp = getXP();
    final currentRank = getCurrentRank();
    final nextRank = getNextRank();

    if (nextRank == null) {
      return 1.0;
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

  // Нарахування XP за відкриття кейсу
  static int calculateXPForCaseOpening(String rarity) {
    final rarityLower = rarity.toLowerCase();

    if (rarityLower.contains('★') ||
        rarityLower.contains('extraordinary') ||
        rarityLower.contains('knife')) {
      return 1000;
    }

    if (rarityLower.contains('covert')) return 100;
    if (rarityLower.contains('classified')) return 50;
    if (rarityLower.contains('restricted')) return 20;
    if (rarityLower.contains('mil-spec')) return 5;
    return 3;
  }
}
