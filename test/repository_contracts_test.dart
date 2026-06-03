import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:performaz/core/network/api_client.dart';
import 'package:performaz/core/repositories/crud_repository.dart';
import 'package:performaz/core/repositories/manager_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;

  setUp(() {
    apiClient = MockApiClient();
  });

  test('CrudRepository updates vendors with the Nest PUT contract', () async {
    final repository = CrudRepository(apiClient: apiClient);
    final data = {'name': 'Carlos Silva'};

    when(
      () => apiClient.put('/vendors/vendor-1', data: data),
    ).thenAnswer((_) async => Response(requestOptions: RequestOptions()));

    await repository.updateVendor('vendor-1', data);

    verify(() => apiClient.put('/vendors/vendor-1', data: data)).called(1);
    verifyNever(() => apiClient.patch('/vendors/vendor-1', data: data));
  });

  test('CrudRepository updates clients with the Nest PUT contract', () async {
    final repository = CrudRepository(apiClient: apiClient);
    final data = {'name': 'Mercado Central'};

    when(
      () => apiClient.put('/clients/client-1', data: data),
    ).thenAnswer((_) async => Response(requestOptions: RequestOptions()));

    await repository.updateClient('client-1', data);

    verify(() => apiClient.put('/clients/client-1', data: data)).called(1);
    verifyNever(() => apiClient.patch('/clients/client-1', data: data));
  });

  test('CrudRepository updates products with the Nest PUT contract', () async {
    final repository = CrudRepository(apiClient: apiClient);
    final data = {'name': 'Acai Premium'};

    when(
      () => apiClient.put('/products/product-1', data: data),
    ).thenAnswer((_) async => Response(requestOptions: RequestOptions()));

    await repository.updateProduct('product-1', data);

    verify(() => apiClient.put('/products/product-1', data: data)).called(1);
    verifyNever(() => apiClient.patch('/products/product-1', data: data));
  });

  test(
    'ManagerRepository fetches live map from the exposed API route',
    () async {
      final repository = ManagerRepository(apiClient: apiClient);

      when(() => apiClient.get('/gamification/map')).thenAnswer(
        (_) async => Response<List<Map<String, dynamic>>>(
          requestOptions: RequestOptions(),
          data: [
            {'vendorId': 'vendor-1', 'lat': 1.0, 'lng': 2.0},
          ],
        ),
      );

      final locations = await repository.fetchVendorLocations();

      expect(locations.single['vendorId'], 'vendor-1');
      verify(() => apiClient.get('/gamification/map')).called(1);
      verifyNever(() => apiClient.get('/gamification/vendor-locations'));
    },
  );
}
