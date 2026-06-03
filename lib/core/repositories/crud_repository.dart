import '../network/api_client.dart';

/// Generic CRUD repository for vendors, clients, and products.
class CrudRepository {
  CrudRepository({required this.apiClient});

  final ApiClient apiClient;

  // --- Vendors ---

  Future<List<Map<String, dynamic>>> fetchVendors() async {
    final response = await apiClient.get('/vendors');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> data) async {
    final response = await apiClient.post('/vendors', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateVendor(String id, Map<String, dynamic> data) async {
    await apiClient.put('/vendors/$id', data: data);
  }

  Future<void> deleteVendor(String id) async {
    await apiClient.delete('/vendors/$id');
  }

  // --- Clients ---

  Future<List<Map<String, dynamic>>> fetchClients() async {
    final response = await apiClient.get('/clients');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    final response = await apiClient.post('/clients', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateClient(String id, Map<String, dynamic> data) async {
    await apiClient.put('/clients/$id', data: data);
  }

  Future<void> deleteClient(String id) async {
    await apiClient.delete('/clients/$id');
  }

  // --- Products ---

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await apiClient.get('/products');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await apiClient.post('/products', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await apiClient.put('/products/$id', data: data);
  }

  Future<void> deleteProduct(String id) async {
    await apiClient.delete('/products/$id');
  }
}
