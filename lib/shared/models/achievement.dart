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
    final nameStr = json['name'] as String? ?? json['title'] as String? ?? '';
    AchievementType type = AchievementType.primeiraVendaDoDia;
    if (nameStr.toLowerCase().contains('primeira')) {
      type = AchievementType.primeiraVendaDoDia;
    } else if (nameStr.toLowerCase().contains('10') || nameStr.toLowerCase().contains('visita')) {
      type = AchievementType.dezClientesVisitados;
    } else if (nameStr.toLowerCase().contains('meta')) {
      type = AchievementType.metaSemanalAtingida;
    } else if (nameStr.toLowerCase().contains('explorador')) {
      type = AchievementType.maratonista;
    }
    return Achievement(
      id: json['id'] as String,
      type: type,
      title: nameStr,
      description: json['description'] as String? ?? '',
      iconName: json['icon'] as String? ?? json['icon_name'] as String? ?? '🏆',
      xpReward: json['xpReward'] as int? ?? json['xp_reward'] as int? ?? 0,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'].toString())
          : (json['unlocked_at'] != null
              ? DateTime.tryParse(json['unlocked_at'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': title,
        'description': description,
        'icon': iconName,
        'xpReward': xpReward,
        'unlockedAt': unlockedAt?.toIso8601String(),
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
      description: json['description'] as String? ?? '',
      xpAmount: json['xpEarned'] as int? ?? json['xp_amount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'xpEarned': xpAmount,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, description, xpAmount, createdAt];
}
