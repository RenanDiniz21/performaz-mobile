import 'package:equatable/equatable.dart';

enum VisitStatus { pendente, visitado, vendaRealizada, visitaSemVenda }

class RouteStop extends Equatable {
  const RouteStop({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.address,
    required this.order,
    this.status = VisitStatus.pendente,
    this.checkinAt,
    this.checkinLatitude,
    this.checkinLongitude,
    this.checkinPhotoUrl,
    this.noSaleReason,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String address;
  final int order;
  final VisitStatus status;
  final DateTime? checkinAt;
  final double? checkinLatitude;
  final double? checkinLongitude;
  final String? checkinPhotoUrl;
  final String? noSaleReason;

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      clientName: json['client_name'] as String,
      address: json['address'] as String,
      order: json['order'] as int,
      status: VisitStatus.values.byName(json['status'] as String),
      checkinAt: json['checkin_at'] != null
          ? DateTime.parse(json['checkin_at'] as String)
          : null,
      checkinLatitude: (json['checkin_latitude'] as num?)?.toDouble(),
      checkinLongitude: (json['checkin_longitude'] as num?)?.toDouble(),
      checkinPhotoUrl: json['checkin_photo_url'] as String?,
      noSaleReason: json['no_sale_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'address': address,
        'order': order,
        'status': status.name,
        'checkin_at': checkinAt?.toIso8601String(),
        'checkin_latitude': checkinLatitude,
        'checkin_longitude': checkinLongitude,
        'checkin_photo_url': checkinPhotoUrl,
        'no_sale_reason': noSaleReason,
      };

  RouteStop copyWith({
    int? order,
    VisitStatus? status,
    DateTime? checkinAt,
    double? checkinLatitude,
    double? checkinLongitude,
    String? checkinPhotoUrl,
    String? noSaleReason,
  }) {
    return RouteStop(
      id: id,
      clientId: clientId,
      clientName: clientName,
      address: address,
      order: order ?? this.order,
      status: status ?? this.status,
      checkinAt: checkinAt ?? this.checkinAt,
      checkinLatitude: checkinLatitude ?? this.checkinLatitude,
      checkinLongitude: checkinLongitude ?? this.checkinLongitude,
      checkinPhotoUrl: checkinPhotoUrl ?? this.checkinPhotoUrl,
      noSaleReason: noSaleReason ?? this.noSaleReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        clientName,
        address,
        order,
        status,
        checkinAt,
        checkinLatitude,
        checkinLongitude,
        checkinPhotoUrl,
        noSaleReason,
      ];
}

class SalesRoute extends Equatable {
  const SalesRoute({
    required this.id,
    required this.sellerId,
    required this.date,
    required this.stops,
  });

  final String id;
  final String sellerId;
  final DateTime date;
  final List<RouteStop> stops;

  int get completedCount =>
      stops.where((s) => s.status != VisitStatus.pendente).length;
  int get totalCount => stops.length;
  double get progressPercent =>
      totalCount > 0 ? completedCount / totalCount : 0;

  factory SalesRoute.fromJson(Map<String, dynamic> json) {
    return SalesRoute(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      date: DateTime.parse(json['date'] as String),
      stops: (json['stops'] as List)
          .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'date': date.toIso8601String(),
        'stops': stops.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, sellerId, date, stops];
}
