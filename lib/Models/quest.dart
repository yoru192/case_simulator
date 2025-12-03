import 'package:hive/hive.dart';

part 'quest.g.dart';

@HiveType(typeId: 5) // 0-item, 1-case, 2-?, 3-user, 4-rank?, 5-quest
enum QuestType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  achievement,
}

@HiveType(typeId: 6)
enum QuestStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  claimed,
}

@HiveType(typeId: 7)
class QuestModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  QuestType type;

  @HiveField(4)
  QuestStatus status;

  @HiveField(5)
  int currentProgress;

  @HiveField(6)
  int requiredProgress;

  @HiveField(7)
  double moneyReward;

  @HiveField(8)
  int xpReward;

  @HiveField(9)
  String userId;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  DateTime? claimedAt;

  @HiveField(12)
  String trackingKey; // Ключ для відстеження: 'cases_opened', 'items_sold', etc.

  QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = QuestStatus.active,
    this.currentProgress = 0,
    required this.requiredProgress,
    required this.moneyReward,
    required this.xpReward,
    required this.userId,
    this.completedAt,
    this.claimedAt,
    required this.trackingKey,
  });

  bool get isCompleted => currentProgress >= requiredProgress;
  bool get isClaimed => status == QuestStatus.claimed;
  bool get canClaim => isCompleted && !isClaimed;
  double get progressPercent => (currentProgress / requiredProgress).clamp(0.0, 1.0);

  void updateProgress(int progress) {
    currentProgress = progress;
    if (isCompleted && status == QuestStatus.active) {
      status = QuestStatus.completed;
      completedAt = DateTime.now();
    }
    save(); // Зберігає в Hive автоматично
  }

  void claim() {
    if (canClaim) {
      status = QuestStatus.claimed;
      claimedAt = DateTime.now();
      save();
    }
  }
}
