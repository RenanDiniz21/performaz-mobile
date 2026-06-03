import 'package:flutter_test/flutter_test.dart';
import 'package:performaz/features/routes/route_cubit.dart';
import 'package:performaz/shared/models/route.dart';

void main() {
  test('RouteStop.fromJson accepts Nest API no-sale status', () {
    final stop = RouteStop.fromJson({
      'id': 'route-client-1',
      'routeId': 'route-1',
      'clientId': 'client-1',
      'clientName': 'Mercado Central',
      'address': 'Rua A, 123',
      'order': 1,
      'status': 'sem_venda',
      'visitReason': 'sem_interesse',
    });

    expect(stop.status, VisitStatus.visitaSemVenda);
    expect(stop.noSaleReason, 'sem_interesse');
  });

  test('buildRouteStops enriches API route clients with client details', () {
    final stops = buildRouteStops(
      routeId: 'route-1',
      routeClients: [
        {
          'id': 'route-client-1',
          'clientId': 'client-1',
          'order': 1,
          'status': 'pendente',
          'checkInTime': null,
          'visitReason': null,
        },
      ],
      clientsById: {
        'client-1': {
          'id': 'client-1',
          'name': 'Escritorios Modernos SA',
          'address': 'Rua Augusta, 500',
          'city': 'Sao Paulo',
          'state': 'SP',
        },
      },
    );

    expect(stops, hasLength(1));
    expect(stops.single.clientName, 'Escritorios Modernos SA');
    expect(stops.single.address, 'Rua Augusta, 500 - Sao Paulo, SP');
    expect(stops.single.status, VisitStatus.pendente);
  });

  test('buildRouteReorderPayload sends client ids with one-based order', () {
    final payload = buildRouteReorderPayload([
      const RouteStop(
        id: 'route-client-2',
        routeId: 'route-1',
        clientId: 'client-2',
        clientName: 'Cliente 2',
        address: '',
        order: 2,
      ),
      const RouteStop(
        id: 'route-client-1',
        routeId: 'route-1',
        clientId: 'client-1',
        clientName: 'Cliente 1',
        address: '',
        order: 1,
      ),
    ]);

    expect(payload, [
      {'clientId': 'client-2', 'order': 1},
      {'clientId': 'client-1', 'order': 2},
    ]);
  });

  test('markRouteStopAsSale updates only the matching client stop', () {
    final stops = markRouteStopAsSale([
      const RouteStop(
        id: 'route-client-1',
        routeId: 'route-1',
        clientId: 'client-1',
        clientName: 'Cliente 1',
        address: '',
        order: 1,
        status: VisitStatus.pendente,
      ),
      const RouteStop(
        id: 'route-client-2',
        routeId: 'route-1',
        clientId: 'client-2',
        clientName: 'Cliente 2',
        address: '',
        order: 2,
        status: VisitStatus.visitado,
      ),
    ], 'client-1');

    expect(stops.first.status, VisitStatus.vendaRealizada);
    expect(stops.last.status, VisitStatus.visitado);
  });

  test('markRouteStopAsNoSale updates only the matching client stop', () {
    final stops = markRouteStopAsNoSale(
      [
        const RouteStop(
          id: 'route-client-1',
          routeId: 'route-1',
          clientId: 'client-1',
          clientName: 'Cliente 1',
          address: '',
          order: 1,
          status: VisitStatus.pendente,
        ),
        const RouteStop(
          id: 'route-client-2',
          routeId: 'route-1',
          clientId: 'client-2',
          clientName: 'Cliente 2',
          address: '',
          order: 2,
          status: VisitStatus.visitado,
        ),
      ],
      'client-1',
      'sem_interesse',
    );

    expect(stops.first.status, VisitStatus.visitaSemVenda);
    expect(stops.first.noSaleReason, 'sem_interesse');
    expect(stops.last.status, VisitStatus.visitado);
  });
}
