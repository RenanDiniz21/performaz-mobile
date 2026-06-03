import 'package:equatable/equatable.dart';

import 'product.dart';

enum OrderStatus { pending, confirmed, delivered, cancelled }

OrderStatus _orderStatusFromJson(String value) {
  return switch (value) {
    'pendente' => OrderStatus.pending,
    'confirmado' => OrderStatus.confirmed,
    'cancelado' => OrderStatus.cancelled,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.values.byName(value),
  };
}

class OrderItem extends Equatable {
  const OrderItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get subtotal => product.unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final product = productJson is Map<String, dynamic>
        ? Product.fromJson(productJson)
        : Product(
            id: json['productId'] as String? ?? json['product_id'] as String,
            name: json['productName'] as String? ??
                json['product_name'] as String? ??
                'Produto',
            unitPrice:
                (json['unitPrice'] as num? ?? json['unit_price'] as num)
                    .toDouble(),
            unitOfMeasure: json['unitOfMeasure'] as String? ??
                json['unit_of_measure'] as String? ??
                'un',
          );

    return OrderItem(
      product: product,
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
      clientId: json['clientId'] as String? ?? json['client_id'] as String,
      sellerId: json['vendorId'] as String? ??
          json['sellerId'] as String? ??
          json['seller_id'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      status: _orderStatusFromJson(json['status'] as String),
      notes: json['notes'] as String?,
      syncedAt: json['syncedAt'] != null || json['synced_at'] != null
          ? DateTime.parse(
              json['syncedAt'] as String? ?? json['synced_at'] as String,
            )
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
