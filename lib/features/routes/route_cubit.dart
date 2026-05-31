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
  RouteCubit({
    required this.apiClient,
    required this.secureStorage,
  }) : super(RouteLoading());

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
        queryParameters: {
          'vendorId': actualVendorId,
          'date': today,
        },
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
        final detail = detailResponse.data as Map<String, dynamic>;
        final clientsList = detail['clients'] as List? ?? [];

        final stops = clientsList.map((e) {
          final map = e as Map<String, dynamic>;
          return RouteStop(
            id: map['id'] as String,
            routeId: routeId,
            clientId: map['clientId'] as String? ?? map['client_id'] as String,
            clientName: map['clientName'] as String? ?? '',
            address: '',
            order: map['order'] as int? ?? 0,
            status: _parseStatus(map['status'] as String? ?? 'pendente'),
            noSaleReason: map['visitReason'] as String? ?? map['visit_reason'] as String?,
            checkinAt: map['checkInTime'] != null
                ? DateTime.tryParse(map['checkInTime'].toString())
                : null,
          );
        }).toList();

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

  VisitStatus _parseStatus(String status) {
    return switch (status) {
      'pendente' => VisitStatus.pendente,
      'visitado' => VisitStatus.visitado,
      'venda_realizada' => VisitStatus.vendaRealizada,
      'sem_venda' => VisitStatus.visitaSemVenda,
      _ => VisitStatus.pendente,
    };
  }

  void reorderStops(int oldIndex, int newIndex) {
    if (state is RouteLoaded) {
      final loaded = state as RouteLoaded;
      final stops = List<RouteStop>.from(loaded.stops);
      final item = stops.removeAt(oldIndex);
      stops.insert(newIndex, item);
      emit(RouteLoaded(stops: stops, routeId: loaded.routeId));
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Sem conexão com o servidor',
      DioExceptionType.badResponse => 'Erro ${e.response?.statusCode}',
      _ => 'Erro de rede',
    };
  }
}
