import 'package:equatable/equatable.dart';

enum AchievementType {
  primeiraVendaDoDia,
  dezClientesVisitados,
  metaSemanalAtingida,
  centuriao, // 100 sales
  maratonista, // 20 visits in a day
  topSemanal, // weekly #1
}

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.xpReward,
    this.unlockedAt,
  });

  final String id;
  final AchievementType type;
  final String title;
  final String description;
  final String iconName;
  final int xpReward;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      type: AchievementType.values.byName(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      xpReward: json['xp_reward'] as int,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'icon_name': iconName,
        'xp_reward': xpReward,
        'unlocked_at': unlockedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, type, title, description, iconName, xpReward, unlockedAt];
}

class XpEvent extends Equatable {
  const XpEvent({
    required this.id,
    required this.description,
    required this.xpAmount,
    required this.createdAt,
  });

  final String id;
  final String description;
  final int xpAmount;
  final DateTime createdAt;

  factory XpEvent.fromJson(Map<String, dynamic> json) {
    return XpEvent(
      id: json['id'] as String,
      description: json['description'] as String,
      xpAmount: json['xp_amount'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'xp_amount': xpAmount,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, description, xpAmount, createdAt];
}
