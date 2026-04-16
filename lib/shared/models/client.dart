import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.address,
    this.code,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.isProspect = false,
    this.isActive = true,
    this.lastVisit,
    this.assignedSellerId,
  });

  final String id;
  final String name;
  final String cnpj;
  final String address;
  final String? code;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final bool isProspect;
  final bool isActive;
  final DateTime? lastVisit;
  final String? assignedSellerId;

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      cnpj: json['cnpj'] as String,
      address: json['address'] as String,
      code: json['code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isProspect: json['is_prospect'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      lastVisit: json['last_visit'] != null
          ? DateTime.parse(json['last_visit'] as String)
          : null,
      assignedSellerId: json['assigned_seller_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cnpj': cnpj,
        'address': address,
        'code': code,
        'phone': phone,
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'is_prospect': isProspect,
        'is_active': isActive,
        'last_visit': lastVisit?.toIso8601String(),
        'assigned_seller_id': assignedSellerId,
      };

  Client copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
    String? assignedSellerId,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      cnpj: cnpj,
      address: address ?? this.address,
      code: code,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isProspect: isProspect,
      isActive: isActive ?? this.isActive,
      lastVisit: lastVisit,
      assignedSellerId: assignedSellerId ?? this.assignedSellerId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        cnpj,
        address,
        code,
        phone,
        email,
        latitude,
        longitude,
        isProspect,
        isActive,
        lastVisit,
        assignedSellerId,
      ];
}
