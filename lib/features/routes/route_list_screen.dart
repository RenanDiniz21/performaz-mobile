import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RouteListState {
  const RouteListState({
    this.route,
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  final SalesRoute? route;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  RouteListState copyWith({
    SalesRoute? route,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return RouteListState(
      route: route ?? this.route,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class RouteCubit extends Cubit<RouteListState> {
  RouteCubit() : super(const RouteListState());

  Future<void> loadRoute() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // TODO: fetch from repository / local DB
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Placeholder — replace with real data source
      final salesRoute = SalesRoute(
        id: 'route-001',
        sellerId: 'seller-001',
        date: DateTime.now(),
        stops: [],
      );

      emit(state.copyWith(route: salesRoute, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar rota: $e',
      ));
    }
  }

  Future<void> syncRoute() async {
    emit(state.copyWith(isSyncing: true));
    try {
      // TODO: sync with API
      await Future<void>.delayed(const Duration(seconds: 1));
      emit(state.copyWith(isSyncing: false));
    } catch (_) {
      emit(state.copyWith(isSyncing: false));
    }
  }

  void reorderStops(int oldIndex, int newIndex) {
    final route = state.route;
    if (route == null) return;

    final stops = List<RouteStop>.from(route.stops);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);

    final reordered = [
      for (int i = 0; i < stops.length; i++) stops[i].copyWith(order: i),
    ];

    emit(state.copyWith(
      route: SalesRoute(
        id: route.id,
        sellerId: route.sellerId,
        date: route.date,
        stops: reordered,
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RouteCubit()..loadRoute(),
      child: const _RouteListView(),
    );
  }
}

class _RouteListView extends StatelessWidget {
  const _RouteListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text('Minha Rota', style: AppTypography.displaySmall),
        centerTitle: false,
        actions: [
          BlocBuilder<RouteCubit, RouteListState>(
            buildWhen: (p, c) => p.isSyncing != c.isSyncing,
            builder: (context, state) {
              return IconButton(
                onPressed: state.isSyncing
                    ? null
                    : () => context.read<RouteCubit>().syncRoute(),
                icon: state.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, color: AppColors.foreground),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: AppTypography.label,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocBuilder<RouteCubit, RouteListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
              child: Text(state.errorMessage!, style: AppTypography.bodyMedium),
            );
          }

          final route = state.route;
          if (route == null || route.stops.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 48, color: AppColors.mutedForeground),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma parada agendada',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _ProgressHeader(route: route),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: route.stops.length,
                  onReorder: context.read<RouteCubit>().reorderStops,
                  itemBuilder: (context, index) {
                    final stop = route.stops[index];
                    return _StopCard(
                      key: ValueKey(stop.id),
                      stop: stop,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress header
// ---------------------------------------------------------------------------

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.route});

  final SalesRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresso', style: AppTypography.bodyMedium),
              Text(
                '${route.completedCount}/${route.totalCount}',
                style: AppTypography.displaySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.smBorder,
            child: LinearProgressIndicator(
              value: route.progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.muted,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stop card
// ---------------------------------------------------------------------------

class _StopCard extends StatelessWidget {
  const _StopCard({super.key, required this.stop, required this.index});

  final RouteStop stop;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        child: InkWell(
          borderRadius: AppRadius.lgBorder,
          onTap: () => context.push('/clients/${stop.clientId}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Order number
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),

                // Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.clientName,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stop.address,
                        style: AppTypography.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status chip
                _StatusChip(status: stop.status),

                const SizedBox(width: 4),
                const Icon(Icons.drag_handle, color: AppColors.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      VisitStatus.pendente => ('Pendente', AppColors.muted, AppColors.mutedForeground),
      VisitStatus.visitado => ('Visitado', AppColors.lowBg, AppColors.lowFg),
      VisitStatus.vendaRealizada => ('Venda', AppColors.successBg, AppColors.success),
      VisitStatus.visitaSemVenda => ('Sem Venda', AppColors.mediumBg, AppColors.mediumFg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smBorder,
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
