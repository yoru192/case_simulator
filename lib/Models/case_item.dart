class CaseItem {
  final String id;
  final String name;
  final String rarity;
  final String rarityColor;
  final String imageUrl;
  final int paintIndex;

  CaseItem({
    required this.id,
    required this.name,
    required this.rarity,
    required this.rarityColor,
    required this.imageUrl,
    required this.paintIndex,
  });

  factory CaseItem.fromJson(Map<String, dynamic> json) {
    return CaseItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rarity: json['rarity']?['name'] as String? ?? 'Unknown',
      rarityColor: json['rarity']?['color'] as String? ?? '#4B69FF',
      imageUrl: json['image'] as String? ?? '',
      paintIndex: json['paint_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rarity': rarity,
      'rarityColor': rarityColor,
      'imageUrl': imageUrl,
      'paintIndex': paintIndex,
    };
  }
}
