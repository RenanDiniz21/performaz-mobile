import '../../shared/models/user.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

class AuthRepository {
  AuthRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  final ApiClient apiClient;
  final SecureStorage secureStorage;

  Future<User> login({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await apiClient.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['access_token'] as String;

    await secureStorage.saveAccessToken(token);
    await secureStorage.saveUserId(user.id);

    if (data['refresh_token'] != null) {
      await secureStorage.saveRefreshToken(data['refresh_token'] as String);
    }

    return user;
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } catch (_) {
      // Best-effort server logout
    }
    await secureStorage.clearTokens();
  }

  Future<User?> getCurrentUser() async {
    final hasToken = await secureStorage.hasToken();
    if (!hasToken) return null;

    try {
      final response = await apiClient.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    await apiClient.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
  }) async {
    final response = await apiClient.put('/auth/profile', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
