import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:performaz/core/auth/auth_repository.dart';
import 'package:performaz/core/network/api_client.dart';
import 'package:performaz/core/storage/secure_storage.dart';
import 'package:performaz/shared/models/user.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorage extends Mock implements SecureStorage {}

String fakeJwt(Map<String, Object?> payload) {
  String encodeJson(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encodeJson({'alg': 'none', 'typ': 'JWT'})}.${encodeJson(payload)}.';
}

Map<String, dynamic> vendorRecord({
  String id = 'vendor-1',
  String name = 'Carlos Silva',
  String email = 'carlos@performaz.com',
  String phone = '(11) 99999-0000',
}) {
  return {
    'id': id,
    'name': name,
    'email': email,
    'matricula': 'V001',
    'phone': phone,
    'avatar': null,
    'status': 'ativo',
    'region': 'Sao Paulo',
    'xp': 120,
    'level': 2,
  };
}

void main() {
  late MockApiClient apiClient;
  late MockSecureStorage secureStorage;
  late AuthRepository repository;

  setUp(() {
    apiClient = MockApiClient();
    secureStorage = MockSecureStorage();
    repository = AuthRepository(
      apiClient: apiClient,
      secureStorage: secureStorage,
    );

    when(() => secureStorage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => secureStorage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => secureStorage.saveUserId(any())).thenAnswer((_) async {});
  });

  test(
    'vendor login hydrates the authenticated user from the vendor API',
    () async {
      final token = fakeJwt({
        'sub': 'vendor-1',
        'email': 'carlos@performaz.com',
        'role': 'VENDEDOR',
      });

      when(
        () => apiClient.post(
          '/auth/vendor/login',
          data: {'matricula': 'V001', 'password': 'vendor123'},
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(),
          data: {'accessToken': token, 'refreshToken': 'refresh-token'},
        ),
      );
      when(() => apiClient.get('/vendors/vendor-1')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(),
          data: vendorRecord(),
        ),
      );

      final user = await repository.login(
        identifier: 'V001',
        password: 'vendor123',
      );

      expect(user.name, 'Carlos Silva');
      expect(user.phone, '(11) 99999-0000');
      expect(user.matricula, 'V001');
      expect(user.role, UserRole.vendedor);
    },
  );

  test(
    'updateVendorProfile sends editable profile fields to the API',
    () async {
      when(
        () => apiClient.put(
          '/vendors/vendor-1',
          data: {'name': 'Carlos Santos', 'phone': '(11) 98888-0000'},
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(),
          data: vendorRecord(name: 'Carlos Santos', phone: '(11) 98888-0000'),
        ),
      );

      final user = await repository.updateVendorProfile(
        vendorId: 'vendor-1',
        name: ' Carlos Santos ',
        phone: ' (11) 98888-0000 ',
      );

      expect(user.name, 'Carlos Santos');
      expect(user.phone, '(11) 98888-0000');
      verify(
        () => apiClient.put(
          '/vendors/vendor-1',
          data: {'name': 'Carlos Santos', 'phone': '(11) 98888-0000'},
        ),
      ).called(1);
    },
  );

  test(
    'changeVendorPassword sends the current and new password to the API',
    () async {
      when(
        () => apiClient.post(
          '/auth/vendor/change-password',
          data: {'currentPassword': 'vendor123', 'newPassword': 'newVendor123'},
        ),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions()));

      await repository.changeVendorPassword(
        currentPassword: ' vendor123 ',
        newPassword: ' newVendor123 ',
      );

      verify(
        () => apiClient.post(
          '/auth/vendor/change-password',
          data: {'currentPassword': 'vendor123', 'newPassword': 'newVendor123'},
        ),
      ).called(1);
    },
  );
}
