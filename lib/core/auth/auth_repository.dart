import 'dart:convert';

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

  /// Login — tries vendor login (matricula) first; if identifier looks like
  /// an email, uses manager login instead.
  Future<User> login({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    final isEmail = identifier.contains('@');

    final response = isEmail
        ? await apiClient.post('/auth/login', data: {
            'email': identifier,
            'password': password,
          })
        : await apiClient.post('/auth/vendor/login', data: {
            'matricula': identifier,
            'password': password,
          });

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await secureStorage.saveAccessToken(accessToken);
    await secureStorage.saveRefreshToken(refreshToken);

    // Decode JWT payload to build User (API doesn't return user object)
    final user = _userFromJwt(accessToken);
    await secureStorage.saveUserId(user.id);

    return user;
  }

  Future<void> logout() async {
    await secureStorage.clearTokens();
  }

  Future<User?> getCurrentUser() async {
    final hasToken = await secureStorage.hasToken();
    if (!hasToken) return null;

    try {
      final token = await secureStorage.getAccessToken();
      if (token == null) return null;
      return _userFromJwt(token);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshToken() async {
    final rt = await secureStorage.getRefreshToken();
    if (rt == null) throw Exception('No refresh token');

    final response = await apiClient.post('/auth/refresh', data: {
      'refreshToken': rt,
    });

    final data = response.data as Map<String, dynamic>;
    await secureStorage.saveAccessToken(data['accessToken'] as String);
    await secureStorage.saveRefreshToken(data['refreshToken'] as String);
  }

  /// Decode a JWT's payload (base64url) without verification.
  User _userFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Invalid JWT');

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(decoded) as Map<String, dynamic>;

    final role = (map['role'] as String? ?? 'VENDEDOR').toLowerCase();

    return User(
      id: map['sub'] as String,
      name: map['email'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: role == 'gestor' ? UserRole.gestor : UserRole.vendedor,
    );
  }
}
