import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/quest.dart';
import 'package:case_simulator/services/quest_service.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Квести',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '🌅 Щоденні'),
            Tab(text: '📅 Тижневі'),
            Tab(text: '🏆 Досягнення'),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<QuestModel>('quests').listenable(),
        builder: (context, Box<QuestModel> box, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _QuestsList(type: QuestType.daily),
              _QuestsList(type: QuestType.weekly),
              _QuestsList(type: QuestType.achievement),
            ],
          );
        },
      ),
    );
  }
}

class _QuestsList extends StatelessWidget {
  final QuestType type;

  const _QuestsList({required this.type});

  @override
  Widget build(BuildContext context) {
    final quests = QuestService.getQuestsByType(type);

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == QuestType.daily
                  ? Icons.wb_sunny
                  : type == QuestType.weekly
                  ? Icons.calendar_month
                  : Icons.emoji_events,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              type == QuestType.daily
                  ? 'Немає щоденних квестів'
                  : type == QuestType.weekly
                  ? 'Немає тижневих квестів'
                  : 'Немає досягнень',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return _QuestCard(quest: quests[index]);
      },
    );
  }
}

class _QuestCard extends StatefulWidget {
  final QuestModel quest;

  const _QuestCard({required this.quest});

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  bool _isLoading = false;

  Future<void> _claimReward() async {
    setState(() => _isLoading = true);

    final success = await QuestService.claimReward(widget.quest);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Отримано: \$${widget.quest.moneyReward.toStringAsFixed(0)} + ${widget.quest.xpReward} XP',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getQuestColor() {
    if (widget.quest.type == QuestType.achievement) {
      return Colors.amber;
    } else if (widget.quest.type == QuestType.weekly) {
      return Colors.purple;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final questColor = _getQuestColor();
    final isCompleted = widget.quest.isCompleted;
    final isClaimed = widget.quest.isClaimed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isClaimed
              ? Colors.grey[800]!
              : isCompleted
              ? Colors.green
              : questColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: questColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.quest.type == QuestType.achievement
                        ? Icons.emoji_events
                        : widget.quest.type == QuestType.weekly
                        ? Icons.calendar_month
                        : Icons.wb_sunny,
                    color: questColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.quest.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isClaimed ? Colors.grey : Colors.white,
                          decoration: isClaimed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        widget.quest.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isClaimed)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Прогрес бар
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Прогрес',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      '${widget.quest.currentProgress}/${widget.quest.requiredProgress}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.quest.progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : questColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Винагорода
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Показуємо винагороду
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green, size: 18),
                          Text(
                            widget.quest.moneyReward.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(
                            '${widget.quest.xpReward} XP',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Кнопка забрати
                if (widget.quest.canClaim)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _claimReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'ЗАБРАТИ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
