import 'package:equatable/equatable.dart';

enum UserRole { vendedor, gestor }

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.matricula,
    this.phone,
    this.photoUrl,
    this.level = 1,
    this.xp = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? matricula;
  final String? phone;
  final String? photoUrl;
  final int level;
  final int xp;
  final bool isActive;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      matricula: json['matricula'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'matricula': matricula,
        'phone': phone,
        'photo_url': photoUrl,
        'level': level,
        'xp': xp,
        'is_active': isActive,
      };

  User copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    int? level,
    int? xp,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      matricula: matricula,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      isActive: isActive,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, role, matricula, phone, photoUrl, level, xp, isActive];
}
