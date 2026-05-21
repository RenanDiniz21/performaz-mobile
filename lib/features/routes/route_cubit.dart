import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/models/route.dart';

abstract class RouteState extends Equatable {
  const RouteState();
  @override
  List<Object?> get props => [];
}

class RouteLoading extends RouteState {}

class RouteLoaded extends RouteState {
  const RouteLoaded({required this.stops});
  final List<RouteStop> stops;

  @override
  List<Object?> get props => [stops];
}

class RouteError extends RouteState {
  const RouteError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class RouteCubit extends Cubit<RouteState> {
  RouteCubit() : super(RouteLoading());

  // ════════════════════════════════════════════════════════════════════
  // 🚧 MOCK — dados falsos para apresentação.
  //    Para integrar com a API real:
  //    1. Descomente a linha com _routeRepository.getTodayRoute()
  //    2. Remova o Future.delayed e o _buildMockStops()
  //    3. Rode: flutter pub get && dart run build_runner build
  // ════════════════════════════════════════════════════════════════════
  Future<void> loadRoute() async {
    emit(RouteLoading());
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // TODO(api): final response = await getIt<ApiClient>().get('/routes/today');
    emit(RouteLoaded(stops: _buildMockStops()));
  }

  List<RouteStop> _buildMockStops() {
    return const [
      RouteStop(
        id: 'stop-001',
        clientId: 'client-001',
        clientName: 'Supermercado Paulistão',
        address: 'Av. Paulista, 1234 — São Paulo, SP',
        order: 0,
        status: VisitStatus.pendente,
      ),
      RouteStop(
        id: 'stop-002',
        clientId: 'client-002',
        clientName: 'Padaria Dona Maria',
        address: 'Rua Augusta, 567 — São Paulo, SP',
        order: 1,
        status: VisitStatus.visitado,
      ),
      RouteStop(
        id: 'stop-003',
        clientId: 'client-003',
        clientName: 'Mercado Bom Preço',
        address: 'Rua Oscar Freire, 890 — São Paulo, SP',
        order: 2,
        status: VisitStatus.pendente,
      ),
      RouteStop(
        id: 'stop-004',
        clientId: 'client-004',
        clientName: 'Loja do João',
        address: 'Rua Haddock Lobo, 321 — São Paulo, SP',
        order: 3,
        status: VisitStatus.visitaSemVenda,
        noSaleReason: 'Cliente fechado',
      ),
      RouteStop(
        id: 'stop-005',
        clientId: 'client-005',
        clientName: 'Distribuidora Central',
        address: 'Av. Rebouças, 2200 — São Paulo, SP',
        order: 4,
        status: VisitStatus.vendaRealizada,
      ),
    ];
  }

  void reorderStops(int oldIndex, int newIndex) {
    if (state is RouteLoaded) {
      final stops = List<RouteStop>.from((state as RouteLoaded).stops);
      final item = stops.removeAt(oldIndex);
      stops.insert(newIndex, item);
      emit(RouteLoaded(stops: stops));
    }
  }
}
