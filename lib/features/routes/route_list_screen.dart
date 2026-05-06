import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';
import 'route_cubit.dart';

class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  String _friendlyError(String? raw) {
    if (raw == null) return 'Erro desconhecido';
    if (raw.contains('connection timeout') || raw.contains('SocketException')) {
      return 'Sem conexão com o servidor.\nVerifique se a API está rodando.';
    }
    if (raw.contains('404')) return 'Recurso não encontrado.';
    if (raw.contains('401') || raw.contains('403')) return 'Sessão expirada. Faça login novamente.';
    if (raw.contains('500')) return 'Erro interno do servidor.';
    return 'Ocorreu um erro. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Rota do Dia', style: AppTypography.title(20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RouteCubit>().loadRoute(),
          ),
        ],
      ),
      body: DotGridBackground(
        child: BlocBuilder<RouteCubit, RouteState>(
          builder: (context, state) {
            if (state is RouteLoading) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (state is RouteError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.statusError),
                    const SizedBox(height: 12),
                    Text(_friendlyError(state.message),
                        style: AppTypography.body(14).copyWith(color: mutedFg),
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<RouteCubit>().loadRoute(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            if (state is RouteLoaded) {
              if (state.stops.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route_outlined, size: 64, color: mutedFg.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Nenhuma visita hoje', style: AppTypography.body(16).copyWith(color: mutedFg)),
                    ],
                  ),
                );
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                buildDefaultDragHandles: true,
                itemCount: state.stops.length,
                onReorder: (oldIndex, newIndex) {
                  context.read<RouteCubit>().reorderStops(
                    oldIndex,
                    newIndex > oldIndex ? newIndex - 1 : newIndex,
                  );
                },
                itemBuilder: (context, index) {
                  final stop = state.stops[index];
                  return Padding(
                    key: ValueKey(stop.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _StopCard(
                      stop: stop,
                      index: index,
                      onTap: () => context.push('/routes/${stop.clientId}', extra: stop),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.index,
    required this.onTap,
  });

  final RouteStop stop;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Index badge
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${index + 1}',
              style: AppTypography.body(14, weight: FontWeight.w700).copyWith(color: primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.clientName,
                  style: AppTypography.body(15, weight: FontWeight.w600).copyWith(color: fgColor),
                ),
                const SizedBox(height: 2),
                Text(
                  stop.address,
                  style: AppTypography.body(13).copyWith(color: mutedFg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: stop.status),
          const SizedBox(width: 4),
          Icon(Icons.drag_handle, color: mutedFg, size: 20),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      VisitStatus.pendente       => ('Pendente', AppColors.statusWarning),
      VisitStatus.visitado       => ('Visitado', AppColors.statusInfo),
      VisitStatus.vendaRealizada => ('Concluído', AppColors.statusSuccess),
      VisitStatus.visitaSemVenda => ('Sem Venda', AppColors.mutedForegroundDark),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.body(11, weight: FontWeight.w600).copyWith(color: color),
      ),
    );
  }
}
