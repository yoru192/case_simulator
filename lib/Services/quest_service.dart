import 'package:hive/hive.dart';
import 'package:case_simulator/Models/quest.dart';
import 'package:case_simulator/services/auth_service.dart';
import 'package:case_simulator/services/balance_service.dart';
import 'package:case_simulator/services/xp_service.dart'; // ← Переконайся що імпортований

class QuestService {
  static const String _lastDailyResetKey = 'last_daily_reset';
  static const String _lastWeeklyResetKey = 'last_weekly_reset';

  // Отримати всі квести користувача
  static List<QuestModel> getUserQuests() {
    final user = AuthService.getCurrentUser();
    if (user == null) return [];

    final questsBox = Hive.box<QuestModel>('quests');
    return questsBox.values
        .where((quest) => quest.userId == user.id)
        .toList();
  }

  // Отримати квести за типом
  static List<QuestModel> getQuestsByType(QuestType type) {
    return getUserQuests().where((q) => q.type == type).toList();
  }

  // Ініціалізація квестів для нового користувача
  static Future<void> initializeQuestsForUser(String userId) async {
    await _createDailyQuests(userId);
    await _createWeeklyQuests(userId);
    await _createAchievements(userId);
  }

  // Перевірка і оновлення квестів
  static Future<void> checkAndResetQuests() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return;

    final settingsBox = Hive.box('settings');
    final now = DateTime.now();

    // Перевірка щоденних квестів
    final lastDailyReset = settingsBox.get('${_lastDailyResetKey}_${user.id}');
    if (lastDailyReset == null || _shouldResetDaily(DateTime.parse(lastDailyReset), now)) {
      await _resetDailyQuests(user.id);
      await settingsBox.put('${_lastDailyResetKey}_${user.id}', now.toIso8601String());
    }

    // Перевірка тижневих квестів
    final lastWeeklyReset = settingsBox.get('${_lastWeeklyResetKey}_${user.id}');
    if (lastWeeklyReset == null || _shouldResetWeekly(DateTime.parse(lastWeeklyReset), now)) {
      await _resetWeeklyQuests(user.id);
      await settingsBox.put('${_lastWeeklyResetKey}_${user.id}', now.toIso8601String());
    }
  }

  static bool _shouldResetDaily(DateTime last, DateTime now) {
    return now.day != last.day || now.month != last.month || now.year != last.year;
  }

  static bool _shouldResetWeekly(DateTime last, DateTime now) {
    return now.difference(last).inDays >= 7 || (last.weekday > 1 && now.weekday == 1);
  }

  // Оновлення прогресу квесту
  static void updateQuestProgress(String trackingKey, int increment) {
    final quests = getUserQuests()
        .where((q) => q.trackingKey == trackingKey && q.status == QuestStatus.active)
        .toList();

    for (var quest in quests) {
      quest.updateProgress(quest.currentProgress + increment);
    }
  }

  // Забрати винагороду
  static Future<bool> claimReward(QuestModel quest) async {
    if (!quest.canClaim) return false;

    // Додаємо гроші
    BalanceService.addMoney(quest.moneyReward);

    // Додаємо XP
    XPService.addXP(quest.xpReward);

    // Відмічаємо як забрано
    quest.claim();

    return true;
  }

  // === СТВОРЕННЯ КВЕСТІВ ===

  static Future<void> _createDailyQuests(String userId) async {
    final questsBox = Hive.box<QuestModel>('quests');

    final dailyQuests = [
      QuestModel(
        id: 'daily_open_cases_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Відкрий 5 кейсів',
        description: 'Відкрий будь-які 5 кейсів',
        type: QuestType.daily,
        requiredProgress: 5,
        moneyReward: 50.0,
        xpReward: 100,
        userId: userId,
        trackingKey: 'cases_opened',
      ),
      QuestModel(
        id: 'daily_sell_items_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Продай 10 скінів',
        description: 'Продай будь-які 10 предметів з інвентаря',
        type: QuestType.daily,
        requiredProgress: 10,
        moneyReward: 30.0,
        xpReward: 50,
        userId: userId,
        trackingKey: 'items_sold',
      ),
      QuestModel(
        id: 'daily_earn_money_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Заробі \$100',
        description: 'Заробі \$100 від продажу скінів',
        type: QuestType.daily,
        requiredProgress: 100,
        moneyReward: 20.0,
        xpReward: 75,
        userId: userId,
        trackingKey: 'money_earned',
      ),
    ];

    for (var quest in dailyQuests) {
      await questsBox.add(quest);
    }
  }

  static Future<void> _createWeeklyQuests(String userId) async {
    final questsBox = Hive.box<QuestModel>('quests');

    final weeklyQuests = [
      QuestModel(
        id: 'weekly_open_cases_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Відкрий 50 кейсів',
        description: 'Відкрий 50 кейсів за тиждень',
        type: QuestType.weekly,
        requiredProgress: 50,
        moneyReward: 500.0,
        xpReward: 1000,
        userId: userId,
        trackingKey: 'cases_opened',
      ),
      QuestModel(
        id: 'weekly_covert_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Отримай Covert скін',
        description: 'Відкрий червоний (Covert) скін з кейсу',
        type: QuestType.weekly,
        requiredProgress: 1,
        moneyReward: 300.0,
        xpReward: 500,
        userId: userId,
        trackingKey: 'covert_dropped',
      ),
    ];

    for (var quest in weeklyQuests) {
      await questsBox.add(quest);
    }
  }

  static Future<void> _createAchievements(String userId) async {
    final questsBox = Hive.box<QuestModel>('quests');

    final achievements = [
      QuestModel(
        id: 'achievement_first_case_${userId}',
        title: '🎉 Новачок',
        description: 'Відкрий свій перший кейс',
        type: QuestType.achievement,
        requiredProgress: 1,
        moneyReward: 100.0,
        xpReward: 200,
        userId: userId,
        trackingKey: 'cases_opened',
      ),
      QuestModel(
        id: 'achievement_100_cases_${userId}',
        title: '📦 Колекціонер',
        description: 'Відкрий 100 кейсів',
        type: QuestType.achievement,
        requiredProgress: 100,
        moneyReward: 1000.0,
        xpReward: 2000,
        userId: userId,
        trackingKey: 'cases_opened',
      ),
      QuestModel(
        id: 'achievement_rare_item_${userId}',
        title: '💎 Везунчик',
        description: 'Отримай Covert (червоний) скін',
        type: QuestType.achievement,
        requiredProgress: 1,
        moneyReward: 500.0,
        xpReward: 1000,
        userId: userId,
        trackingKey: 'covert_dropped',
      ),
      QuestModel(
        id: 'achievement_10k_earned_${userId}',
        title: '💰 Торговець',
        description: 'Заробі \$10,000 від продажу скінів',
        type: QuestType.achievement,
        requiredProgress: 10000,
        moneyReward: 2000.0,
        xpReward: 5000,
        userId: userId,
        trackingKey: 'money_earned',
      ),
      QuestModel(
        id: 'achievement_knife_${userId}',
        title: '🔪 Легенда',
        description: 'Відкрий ніж із кейсу',
        type: QuestType.achievement,
        requiredProgress: 1,
        moneyReward: 5000.0,
        xpReward: 10000,
        userId: userId,
        trackingKey: 'knife_dropped',
      ),
    ];

    for (var quest in achievements) {
      await questsBox.add(quest);
    }
  }

  static Future<void> _resetDailyQuests(String userId) async {
    final questsBox = Hive.box<QuestModel>('quests');

    final oldDailyQuests = questsBox.values
        .where((q) => q.userId == userId && q.type == QuestType.daily)
        .toList();

    for (var quest in oldDailyQuests) {
      await quest.delete();
    }

    await _createDailyQuests(userId);
  }

  static Future<void> _resetWeeklyQuests(String userId) async {
    final questsBox = Hive.box<QuestModel>('quests');

    final oldWeeklyQuests = questsBox.values
        .where((q) => q.userId == userId && q.type == QuestType.weekly)
        .toList();

    for (var quest in oldWeeklyQuests) {
      await quest.delete();
    }

    await _createWeeklyQuests(userId);
  }
}
