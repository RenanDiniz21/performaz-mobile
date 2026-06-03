import '../../shared/models/order.dart';
import '../network/api_client.dart';

class OrderRepository {
  OrderRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Order>> fetchOrders({required String vendorId}) async {
    final response = await apiClient.get(
      '/orders',
      queryParameters: {'vendorId': vendorId},
    );
    final list = response.data as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> fetchOrder(String id) async {
    final response = await apiClient.get('/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> createOrder({
    required String vendorId,
    required String clientId,
    required List<OrderItem> items,
    String? notes,
  }) async {
    final response = await apiClient.post(
      '/orders',
      data: buildCreateOrderPayload(
        vendorId: vendorId,
        clientId: clientId,
        items: items,
        notes: notes,
      ),
    );
    return Order.fromJson(response.data as Map<String, dynamic>);
  }
}

Map<String, dynamic> buildCreateOrderPayload({
  required String vendorId,
  required String clientId,
  required List<OrderItem> items,
  String? notes,
}) {
  final trimmedNotes = notes?.trim();

  return {
    'vendorId': vendorId,
    'clientId': clientId,
    'items': items
        .map(
          (item) => {
            'productId': item.product.id,
            'quantity': item.quantity,
            'unitPrice': item.product.unitPrice,
          },
        )
        .toList(),
    'notes': trimmedNotes == null || trimmedNotes.isEmpty ? null : trimmedNotes,
  };
}
