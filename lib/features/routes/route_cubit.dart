import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/route.dart';

import '../../core/storage/secure_storage.dart';

abstract class RouteState extends Equatable {
  const RouteState();
  @override
  List<Object?> get props => [];
}

class RouteLoading extends RouteState {}

class RouteLoaded extends RouteState {
  const RouteLoaded({required this.stops, this.routeId});
  final List<RouteStop> stops;
  final String? routeId;

  @override
  List<Object?> get props => [stops, routeId];
}

class RouteError extends RouteState {
  const RouteError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class RouteEmpty extends RouteState {}

class RouteCubit extends Cubit<RouteState> {
  RouteCubit({required this.apiClient, required this.secureStorage})
    : super(RouteLoading());

  final ApiClient apiClient;
  final SecureStorage secureStorage;

  Future<void> loadRoute([String? vendorId]) async {
    emit(RouteLoading());
    try {
      final actualVendorId = vendorId ?? await secureStorage.getUserId();
      if (actualVendorId == null) {
        emit(const RouteError(message: 'Usuário não autenticado.'));
        return;
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await apiClient.get(
        '/routes',
        queryParameters: {'vendorId': actualVendorId, 'date': today},
      );

      final data = response.data;
      if (data is List && data.isEmpty) {
        emit(RouteEmpty());
        return;
      }

      // Response is an array of routes; take the first one for today
      final routes = data as List;
      final routeData = routes.first as Map<String, dynamic>;
      final routeId = routeData['id'] as String?;

      // Fetch full route details with clients
      if (routeId != null) {
        final detailResponse = await apiClient.get('/routes/$routeId');
        final clientsResponse = await apiClient.get('/clients');
        final detail = detailResponse.data as Map<String, dynamic>;
        final clientsList = detail['clients'] as List? ?? [];
        final clientRows = (clientsResponse.data as List? ?? [])
            .whereType<Map<String, dynamic>>();
        final clientsById = {
          for (final client in clientRows) client['id'] as String: client,
        };
        final stops = buildRouteStops(
          routeId: routeId,
          routeClients: clientsList.whereType<Map<String, dynamic>>(),
          clientsById: clientsById,
        );

        emit(RouteLoaded(stops: stops, routeId: routeId));
      } else {
        emit(RouteEmpty());
      }
    } on DioException catch (e) {
      emit(RouteError(message: _parseDioError(e)));
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> reorderStops(int oldIndex, int newIndex) async {
    if (state is RouteLoaded) {
      final loaded = state as RouteLoaded;
      final stops = List<RouteStop>.from(loaded.stops);
      final item = stops.removeAt(oldIndex);
      stops.insert(newIndex, item);
      emit(RouteLoaded(stops: stops, routeId: loaded.routeId));
      if (loaded.routeId != null) {
        try {
          await apiClient.patch(
            '/routes/${loaded.routeId}/reorder',
            data: buildRouteReorderPayload(stops),
          );
        } catch (_) {
          emit(loaded);
        }
      }
    }
  }

  void markClientSale(String clientId) {
    final current = state;
    if (current is! RouteLoaded) return;

    emit(
      RouteLoaded(
        stops: markRouteStopAsSale(current.stops, clientId),
        routeId: current.routeId,
      ),
    );
  }

  void markClientNoSale(String clientId, String reason) {
    final current = state;
    if (current is! RouteLoaded) return;

    emit(
      RouteLoaded(
        stops: markRouteStopAsNoSale(current.stops, clientId, reason),
        routeId: current.routeId,
      ),
    );
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Sem conexão com o servidor',
      DioExceptionType.badResponse => 'Erro ${e.response?.statusCode}',
      _ => 'Erro de rede',
    };
  }
}

List<RouteStop> buildRouteStops({
  required String routeId,
  required Iterable<Map<String, dynamic>> routeClients,
  required Map<String, Map<String, dynamic>> clientsById,
}) {
  return routeClients.map((map) {
    final clientId = map['clientId'] as String? ?? map['client_id'] as String;
    final client = clientsById[clientId];
    return RouteStop(
      id: map['id'] as String,
      routeId: routeId,
      clientId: clientId,
      clientName:
          map['clientName'] as String? ??
          client?['name'] as String? ??
          'Cliente',
      address: _formatClientAddress(client),
      order: map['order'] as int? ?? 0,
      status: parseVisitStatus(map['status'] as String? ?? 'pendente'),
      noSaleReason:
          map['visitReason'] as String? ?? map['visit_reason'] as String?,
      checkinAt: map['checkInTime'] != null
          ? DateTime.tryParse(map['checkInTime'].toString())
          : null,
    );
  }).toList();
}

VisitStatus parseVisitStatus(String status) {
  return switch (status) {
    'pendente' => VisitStatus.pendente,
    'visitado' => VisitStatus.visitado,
    'venda_realizada' => VisitStatus.vendaRealizada,
    'sem_venda' => VisitStatus.visitaSemVenda,
    _ => VisitStatus.pendente,
  };
}

String _formatClientAddress(Map<String, dynamic>? client) {
  if (client == null) return '';
  final street = client['address'] as String? ?? '';
  final city = client['city'] as String? ?? '';
  final state = client['state'] as String? ?? '';
  final location = [city, state].where((part) => part.isNotEmpty).join(', ');
  if (street.isEmpty) return location;
  if (location.isEmpty) return street;
  return '$street - $location';
}

List<Map<String, dynamic>> buildRouteReorderPayload(List<RouteStop> stops) {
  return stops.indexed
      .map((entry) => {'clientId': entry.$2.clientId, 'order': entry.$1 + 1})
      .toList();
}

List<RouteStop> markRouteStopAsSale(List<RouteStop> stops, String clientId) {
  return stops
      .map(
        (stop) => stop.clientId == clientId
            ? stop.copyWith(status: VisitStatus.vendaRealizada)
            : stop,
      )
      .toList();
}

List<RouteStop> markRouteStopAsNoSale(
  List<RouteStop> stops,
  String clientId,
  String reason,
) {
  return stops
      .map(
        (stop) => stop.clientId == clientId
            ? stop.copyWith(
                status: VisitStatus.visitaSemVenda,
                noSaleReason: reason,
              )
            : stop,
      )
      .toList();
}
