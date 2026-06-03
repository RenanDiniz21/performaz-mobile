import '../network/api_client.dart';

class ManagerRepository {
  ManagerRepository({required this.apiClient});

  final ApiClient apiClient;

  // --- Dashboard ---

  Future<Map<String, dynamic>> fetchKpis() async {
    final response = await apiClient.get('/dashboard/kpis');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchDailyRevenue({int days = 7}) async {
    final response = await apiClient.get(
      '/dashboard/revenue',
      queryParameters: {'days': days},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Live Map ---

  Future<List<Map<String, dynamic>>> fetchVendorLocations() async {
    final response = await apiClient.get('/gamification/map');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Goals ---

  Future<List<Map<String, dynamic>>> fetchGoals({String? vendorId}) async {
    final response = await apiClient.get(
      '/goals',
      queryParameters: vendorId != null ? {'vendorId': vendorId} : null,
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> createGoal(Map<String, dynamic> data) async {
    await apiClient.post('/goals', data: data);
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    await apiClient.put('/goals/$id', data: data);
  }

  Future<List<Map<String, dynamic>>> fetchVendors() async {
    final response = await apiClient.get('/vendors');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Notifications ---

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await apiClient.get('/notifications');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    required bool targetAll,
    List<String>? vendorIds,
  }) async {
    await apiClient.post(
      '/notifications',
      data: {
        'title': title,
        'message': message,
        'type': 'info',
        'targetAll': targetAll,
        'targetVendorIds': vendorIds,
      },
    );
  }
}
