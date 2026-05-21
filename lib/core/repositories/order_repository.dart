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
}
