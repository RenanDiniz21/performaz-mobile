import 'package:equatable/equatable.dart';

import 'product.dart';

enum OrderStatus { pending, confirmed, delivered, cancelled }

class OrderItem extends Equatable {
  const OrderItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get subtotal => product.unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  OrderItem copyWith({int? quantity}) {
    return OrderItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.clientId,
    required this.sellerId,
    required this.items,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.notes,
    this.syncedAt,
  });

  final String id;
  final String clientId;
  final String sellerId;
  final List<OrderItem> items;
  final DateTime createdAt;
  final OrderStatus status;
  final String? notes;
  final DateTime? syncedAt;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  bool get isSynced => syncedAt != null;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      sellerId: json['seller_id'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: OrderStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'seller_id': sellerId,
        'items': items.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'synced_at': syncedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, clientId, sellerId, items, createdAt, status, notes, syncedAt];
}
