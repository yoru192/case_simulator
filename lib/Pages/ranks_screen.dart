import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/rank.dart';
import 'package:case_simulator/services/xp_service.dart';

class RanksScreen extends StatelessWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Система Рангів'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: false, // Прибираємо кнопку назад
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(),
        builder: (context, box, _) {
          final currentRank = XPService.getCurrentRank();
          final nextRank = XPService.getNextRank();
          final currentXP = XPService.getXP();
          final xpToNext = XPService.getXPToNextRank();
          final progress = XPService.getProgressToNextRank();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ← ГОЛОВНА КАРТКА З XP
                _CurrentRankCard(
                  rank: currentRank,
                  nextRank: nextRank,
                  currentXP: currentXP,
                  xpToNext: xpToNext,
                  progress: progress,
                ),

                const SizedBox(height: 24),

                // Інформація про нарахування XP
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Як заробити XP:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _XPInfoRow(
                        icon: Icons.star,
                        text: 'Covert предмет',
                        xp: '10-13 XP',
                        color: const Color(0xFFEB4B4B),
                      ),
                      _XPInfoRow(
                        icon: Icons.star_half,
                        text: 'Classified предмет',
                        xp: '7-9 XP',
                        color: const Color(0xFFD32CE6),
                      ),
                      _XPInfoRow(
                        icon: Icons.star_border,
                        text: 'Restricted предмет',
                        xp: '5-6 XP',
                        color: const Color(0xFF8847FF),
                      ),
                      _XPInfoRow(
                        icon: Icons.circle,
                        text: 'Mil-Spec предмет',
                        xp: '3-5 XP',
                        color: const Color(0xFF4B69FF),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Всі ранги:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Список рангів
                ...RankData.ranks.map((rank) {
                  final isUnlocked = currentXP >= rank.requiredXP;
                  final isCurrent = rank.level == currentRank.level;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.purple.withOpacity(0.3),
                        ],
                      )
                          : null,
                      color: isCurrent ? null : Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? Colors.blue
                            : isUnlocked
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                        width: isCurrent ? 3 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            rank.iconPath,
                            style: TextStyle(
                              fontSize: 24,
                              color: isUnlocked ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        rank.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.white : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        '${rank.requiredXP} XP',
                        style: TextStyle(
                          color: isUnlocked ? Colors.blue : Colors.grey,
                        ),
                      ),
                      trailing: isCurrent
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ПОТОЧНИЙ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : isUnlocked
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.lock, color: Colors.grey),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ← НОВА КАРТКА З XP
class _CurrentRankCard extends StatelessWidget {
  final dynamic rank;
  final dynamic nextRank;
  final int currentXP;
  final int xpToNext;
  final double progress;

  const _CurrentRankCard({
    required this.rank,
    required this.nextRank,
    required this.currentXP,
    required this.xpToNext,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.4),
            Colors.purple.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Іконка рангу
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 3),
            ),
            child: Center(
              child: Text(
                rank.iconPath,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Назва рангу
          Text(
            rank.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Level
          Text(
            'Level ${rank.level + 1}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),

          const SizedBox(height: 20),

          // ← ЗАГАЛЬНИЙ XP (ВЕЛИКИЙ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text(
                  '$currentXP XP',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          if (nextRank != null) ...[
            const SizedBox(height: 24),

            // Прогрес до наступного рангу
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'До ${nextRank.name}:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$xpToNext XP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],

          if (nextRank == null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'МАКСИМАЛЬНИЙ РАНГ!',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _XPInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String xp;
  final Color color;

  const _XPInfoRow({
    required this.icon,
    required this.text,
    required this.xp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
          Text(
            xp,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
