import 'dart:math';
import 'package:case_simulator/Services/auth_service.dart';
import 'package:case_simulator/Services/balance_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/Models/item.dart';
import 'package:case_simulator/Services/xp_service.dart';
import 'package:case_simulator/Services/api_service.dart';
import 'package:case_simulator/services/quest_service.dart';

class CaseOpeningScreen extends StatefulWidget {
  final CaseModel caseModel;

  const CaseOpeningScreen({
    super.key,
    required this.caseModel,
  });

  @override
  State<CaseOpeningScreen> createState() => _CaseOpeningScreenState();
}

class _CaseOpeningScreenState extends State<CaseOpeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<CaseItem> _items;
  CaseItem? _wonItem;
  double? _wonItemPrice;
  int? _earnedXP;
  bool _isSpinning = false;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _prepareItems();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _wonItem = _items[25];
        _wonItemPrice = _calculateItemPrice(_wonItem!.rarity, widget.caseModel.price);

        // Нараховуємо XP і зберігаємо
        _earnedXP = XPService.calculateXPForCaseOpening(_wonItem!.rarity);
        XPService.addXP(_earnedXP!);

        // 🎯 ІНКРЕМЕНТ RECOIL
        if (widget.caseModel.name.toLowerCase().contains('recoil')) {
          ApiService.incrementRecoilCounter().then((_) {
            final remaining = ApiService.getRecoilFreeOpensRemaining();
            print('🎮 Recoil відкрито! Залишилось безкоштовних: $remaining');
          });
        }

        // ✅ ОНОВЛЕННЯ КВЕСТІВ ОДРАЗУ ПІСЛЯ ВІДКРИТТЯ
        _updateQuests();

        print('═══════════════════════════════════');
        print('Анімація завершена!');
        print('Виграшний предмет: ${_wonItem!.name}');
        print('Рідкість: ${_wonItem!.rarity}');
        print('Ціна: \$$_wonItemPrice');
        print('Нараховано XP: +$_earnedXP');
        print('═══════════════════════════════════');

        setState(() {
          _showResult = true;
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _startSpin();
    });
  }

  void _prepareItems() {
    _items = [];
    final random = Random();

    for (int i = 0; i < 50; i++) {
      _items.add(widget.caseModel.items[random.nextInt(widget.caseModel.items.length)]);
    }

    final selectedItem = _selectRandomItemByRarity();
    _items[25] = selectedItem;

    print('═══════════════════════════════════════════════════════════');
    print('ВСІ 50 ПРЕДМЕТІВ В КОЛЕСІ:');
    print('═══════════════════════════════════════════════════════════');
    for (int i = 0; i < _items.length; i++) {
      if (i == 25) {
        print('→ [$i] ${_items[i].name} (${_items[i].rarity}) ← ★ ВИГРАШНИЙ ★');
      } else {
        print('  [$i] ${_items[i].name} (${_items[i].rarity})');
      }
    }
    print('═══════════════════════════════════════════════════════════');
  }

  CaseItem _selectRandomItemByRarity() {
    final random = Random();
    final roll = random.nextDouble() * 100;

    // ✅ ФІЛЬТРУЄМО НОЖІ (мають ★ або Extraordinary в назві рідкості)
    final knifeItems = widget.caseModel.items.where((item) {
      final rarityName = item.rarity.toLowerCase();
      return rarityName.contains('★') ||
          rarityName.contains('extraordinary') ||
          item.name.toLowerCase().contains('★');
    }).toList();

    // Звичайні Covert (БЕЗ ножів)
    final covertItems = widget.caseModel.items.where((item) {
      final rarityName = item.rarity.toLowerCase();
      return rarityName.contains('covert') &&
          !rarityName.contains('★') &&
          !rarityName.contains('extraordinary') &&
          !item.name.toLowerCase().contains('★');
    }).toList();

    final classifiedItems = widget.caseModel.items.where(
            (item) => item.rarity.toLowerCase().contains('classified')
    ).toList();

    final restrictedItems = widget.caseModel.items.where(
            (item) => item.rarity.toLowerCase().contains('restricted')
    ).toList();

    final milSpecItems = widget.caseModel.items.where(
            (item) => item.rarity.toLowerCase().contains('mil-spec')
    ).toList();

    // ШАНСИ CS:GO:
    // 0.26% - Ніж
    // 0.64% - Covert
    // 3.2% - Classified
    // 15.98% - Restricted
    // 79.92% - Mil-Spec

    if (roll < 0.26 && knifeItems.isNotEmpty) {
      final knife = knifeItems[random.nextInt(knifeItems.length)];
      print('🔪 ВИПАВ НІЖ: ${knife.name} (шанс: 0.26%)');
      return knife;
    } else if (roll < 0.90 && covertItems.isNotEmpty) {
      return covertItems[random.nextInt(covertItems.length)];
    } else if (roll < 4.10 && classifiedItems.isNotEmpty) {
      return classifiedItems[random.nextInt(classifiedItems.length)];
    } else if (roll < 20.08 && restrictedItems.isNotEmpty) {
      return restrictedItems[random.nextInt(restrictedItems.length)];
    } else if (milSpecItems.isNotEmpty) {
      return milSpecItems[random.nextInt(milSpecItems.length)];
    }

    return widget.caseModel.items[random.nextInt(widget.caseModel.items.length)];
  }

  void _startSpin() {
    setState(() {
      _isSpinning = true;
    });

    final startOffset = 2900.0;
    final endOffset = -79.0;
    final distance = (startOffset - endOffset).abs();
    final baseSpeed = 600.0;
    final calculatedDuration = (distance / baseSpeed).clamp(3.0, 8.0);

    print('Відстань: $distance px, Тривалість: $calculatedDuration сек');

    _controller.duration = Duration(milliseconds: (calculatedDuration * 1000).toInt());
    _controller.forward();
  }

  void _saveToInventory() {
    final inventoryBox = Hive.box<ItemModel>('inventory');
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) return;

    final price = _calculateItemPrice(_wonItem!.rarity, widget.caseModel.price);
    final newItem = ItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _wonItem!.name,
      weapon: _wonItem!.name.split('|')[0].trim(),
      skin: _wonItem!.name.contains('|') ? _wonItem!.name.split('|')[1].trim() : '',
      price: price,
      rarity: _wonItem!.rarity,
      imageUrl: _wonItem!.imageUrl,
      acquiredAt: DateTime.now(),
      userId: currentUser.id,
    );

    inventoryBox.add(newItem);

    print('✅ Предмет додано в інвентар');
  }



  void _sellItemImmediately() {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null || _wonItemPrice == null) return;

    BalanceService.addMoney(_wonItemPrice!);

    // Оновлюємо квести продажу
    QuestService.updateQuestProgress('items_sold', 1);
    QuestService.updateQuestProgress('money_earned', _wonItemPrice!.toInt());

    print('💰 Квести оновлено: items_sold +1, money_earned +${_wonItemPrice!.toInt()}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Продано за \$${_wonItemPrice!.toStringAsFixed(2)}!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateQuests() {
    // 1. Завжди оновлюємо лічильник відкритих кейсів
    QuestService.updateQuestProgress('cases_opened', 1);
    print('✅ Квест оновлено: cases_opened +1');

    final rarityLower = _wonItem!.rarity.toLowerCase();

    // 2. Перевірка на ніж
    if (rarityLower.contains('★') ||
        rarityLower.contains('extraordinary') ||
        _wonItem!.name.toLowerCase().contains('★')) {
      QuestService.updateQuestProgress('knife_dropped', 1);
      print('🔪 Квест оновлено: knife_dropped +1');
    }
    // 3. Перевірка на Covert (але не ніж)
    else if (rarityLower.contains('covert')) {
      QuestService.updateQuestProgress('covert_dropped', 1);
      print('💎 Квест оновлено: covert_dropped +1');
    }
  }


  double _calculateItemPrice(String rarity, double casePrice) {
    final random = Random();
    final rarityLower = rarity.toLowerCase();
    final caseMultiplier = (casePrice / 4.0).clamp(0.5, 10.0);

    // ✅ НОЖІ - ДОРОГІ
    if (rarityLower.contains('★') ||
        rarityLower.contains('extraordinary') ||
        rarityLower.contains('knife')) {
      final base = 200.0 + random.nextDouble() * 800.0; // $200-$1000
      final bonus = random.nextDouble() < 0.2 ? random.nextDouble() * 1000.0 : 0;
      print('💰 Ціна ножа: \$${(base + bonus) * caseMultiplier}');
      return (base + bonus) * caseMultiplier;
    }

    if (rarityLower.contains('covert')) {
      final base = 50.0 + random.nextDouble() * 150.0;
      final bonus = random.nextDouble() < 0.1 ? random.nextDouble() * 300.0 : 0;
      return (base + bonus) * caseMultiplier;
    }

    if (rarityLower.contains('classified')) {
      final base = 8.0 + random.nextDouble() * 22.0;
      final bonus = random.nextDouble() < 0.15 ? random.nextDouble() * 30.0 : 0;
      return (base + bonus) * caseMultiplier;
    }

    if (rarityLower.contains('restricted')) {
      return (1.50 + random.nextDouble() * 13.50) * caseMultiplier;
    }

    if (rarityLower.contains('mil-spec')) {
      return (0.05 + random.nextDouble() * 4.95) * caseMultiplier;
    }

    return (0.10 + random.nextDouble() * 2.0) * caseMultiplier;
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    final rarityLower = rarity.toLowerCase();

    // ✅ ЗОЛОТИЙ ДЛЯ НОЖІВ
    if (rarityLower.contains('★') ||
        rarityLower.contains('extraordinary') ||
        rarityLower.contains('knife')) {
      return const Color(0xFFFFD700); // Золотий
    }

    if (rarityLower.contains('covert')) {
      return const Color(0xFFEB4B4B); // Червоний
    }

    if (rarityLower.contains('classified')) {
      return const Color(0xFFD32CE6); // Рожевий
    }

    if (rarityLower.contains('restricted')) {
      return const Color(0xFF8847FF); // Фіолетовий
    }

    return const Color(0xFF4B69FF); // Синій
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('Opening ${widget.caseModel.name}'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: !_isSpinning,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Spacer(),
              Container(
                height: 200,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ClipRect(
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final itemWidth = 150.0;
                            final startOffset = 2900.0;
                            final endOffset = -79.0;
                            final currentOffset = startOffset + (endOffset - startOffset) * _animation.value;

                            return Transform.translate(
                              offset: Offset(currentOffset, 0),
                              child: Row(
                                children: _items.asMap().entries.map((entry) {
                                  return _ItemCard(
                                    item: entry.value,
                                    width: itemWidth,
                                    rarityColor: _getRarityColor(entry.value.rarity),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 4,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          if (_showResult && _wonItem != null && _wonItemPrice != null && _earnedXP != null)
            _ResultPopup(
              item: _wonItem!,
              price: _wonItemPrice!,
              earnedXP: _earnedXP!,
              rarityColor: _getRarityColor(_wonItem!.rarity),

              onSell: () {
                _sellItemImmediately();
                Navigator.pop(context);
              },
              onKeep: () {
                _saveToInventory();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CaseItem item;
  final double width;
  final Color rarityColor;

  const _ItemCard({
    required this.item,
    required this.width,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D2D2D),
            rarityColor.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rarityColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container();
                },
              )
                  : Container(),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPopup extends StatefulWidget {
  final CaseItem item;
  final double price;
  final Color rarityColor;
  final int earnedXP;
  final VoidCallback onSell;
  final VoidCallback onKeep;

  const _ResultPopup({
    required this.item,
    required this.price,
    required this.rarityColor,
    required this.earnedXP,
    required this.onSell,
    required this.onKeep,
  });

  @override
  State<_ResultPopup> createState() => _ResultPopupState();
}

class _ResultPopupState extends State<_ResultPopup> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isKnife = false;

  @override
  void initState() {
    super.initState();

    // Перевіряємо чи це ніж
    final rarityLower = widget.item.rarity.toLowerCase();
    _isKnife = rarityLower.contains('★') ||
        rarityLower.contains('extraordinary') ||
        widget.item.name.toLowerCase().contains('★');

    // Якщо ніж - додаємо пульсацію
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isKnife ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isKnife
                        ? [
                      const Color(0xFFFFD700).withOpacity(0.4),
                      const Color(0xFFFFA500).withOpacity(0.3),
                      const Color(0xFF1F1F1F),
                    ]
                        : [
                      widget.rarityColor.withOpacity(0.3),
                      const Color(0xFF1F1F1F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.rarityColor,
                    width: _isKnife ? 4 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.rarityColor.withOpacity(0.6),
                      blurRadius: _isKnife ? 40 : 30,
                      spreadRadius: _isKnife ? 10 : 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ ЗАГОЛОВОК З ІКОНКОЮ НОЖА
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isKnife) ...[
                          const Icon(
                            Icons.flash_on,
                            color: Color(0xFFFFD700),
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _isKnife ? 'LEGENDARY KNIFE!' : 'YOU WON!',
                          style: TextStyle(
                            fontSize: _isKnife ? 36 : 32,
                            fontWeight: FontWeight.bold,
                            color: _isKnife ? const Color(0xFFFFD700) : widget.rarityColor,
                            shadows: _isKnife
                                ? [
                              Shadow(
                                color: const Color(0xFFFFD700),
                                blurRadius: 20,
                              ),
                            ]
                                : null,
                          ),
                        ),
                        if (_isKnife) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.flash_on,
                            color: Color(0xFFFFD700),
                            size: 32,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Зображення з анімацією обертання для ножів
                    _isKnife
                        ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159, // 360 градусів
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: widget.item.imageUrl.isNotEmpty
                                ? Image.network(
                              widget.item.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported, size: 120);
                              },
                            )
                                : const Icon(Icons.image_not_supported, size: 120),
                          ),
                        );
                      },
                    )
                        : SizedBox(
                      width: 200,
                      height: 200,
                      child: widget.item.imageUrl.isNotEmpty
                          ? Image.network(
                        widget.item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported, size: 100);
                        },
                      )
                          : const Icon(Icons.image_not_supported, size: 100),
                    ),

                    const SizedBox(height: 20),

                    // Назва предмета
                    Text(
                      widget.item.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _isKnife ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: _isKnife
                            ? [
                          Shadow(
                            color: const Color(0xFFFFD700),
                            blurRadius: 10,
                          ),
                        ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Рідкість
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.rarityColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.rarityColor, width: 2),
                      ),
                      child: Text(
                        widget.item.rarity,
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.rarityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ціна та XP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ціна
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Text(
                            '\$${widget.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: _isKnife ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // XP
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isKnife ? const Color(0xFFFFD700) : Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: _isKnife ? const Color(0xFFFFD700) : Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${widget.earnedXP} XP',
                                style: TextStyle(
                                  fontSize: _isKnife ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: _isKnife ? const Color(0xFFFFD700) : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Кнопки
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onSell,
                            icon: const Icon(Icons.attach_money, color: Colors.white),
                            label: const Text(
                              'ПРОДАТИ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onKeep,
                            icon: const Icon(Icons.inventory, color: Colors.white),
                            label: const Text(
                              'ЗАЛИШИТИ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.rarityColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


