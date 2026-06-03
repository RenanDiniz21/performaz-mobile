import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/core/repositories/order_repository.dart';
import 'package:performaz/shared/models/order.dart';
import 'package:performaz/shared/models/product.dart';

void main() {
  test('buildCreateOrderPayload sends the Nest API order contract', () {
    final payload = buildCreateOrderPayload(
      vendorId: 'vendor-1',
      clientId: 'client-1',
      notes: '',
      items: [
        const OrderItem(
          product: Product(
            id: 'product-1',
            name: 'Notebook',
            unitPrice: 3499.9,
            unitOfMeasure: 'un',
          ),
          quantity: 2,
        ),
      ],
    );

    expect(payload, {
      'vendorId': 'vendor-1',
      'clientId': 'client-1',
      'items': [
        {'productId': 'product-1', 'quantity': 2, 'unitPrice': 3499.9},
      ],
      'notes': null,
    });
  });

  test('Order.fromJson accepts API camelCase order fields and statuses', () {
    final order = Order.fromJson({
      'id': 'order-1',
      'clientId': 'client-1',
      'vendorId': 'vendor-1',
      'items': [
        {
          'productId': 'product-1',
          'quantity': 2,
          'unitPrice': 3499.9,
          'subtotal': 6999.8,
        },
      ],
      'createdAt': '2026-06-02T12:00:00.000Z',
      'status': 'pendente',
      'notes': 'Entrega urgente',
    });

    expect(order.clientId, 'client-1');
    expect(order.sellerId, 'vendor-1');
    expect(order.status, OrderStatus.pending);
    expect(order.items.single.product.id, 'product-1');
    expect(order.items.single.product.unitPrice, 3499.9);
    expect(order.total, 6999.8);
  });
}
