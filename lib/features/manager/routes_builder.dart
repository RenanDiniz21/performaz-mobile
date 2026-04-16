import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _SellerItem {
  const _SellerItem(this.id, this.name);
  final String id;
  final String name;
}

class _ClientItem {
  const _ClientItem(this.id, this.name, this.address);
  final String id;
  final String name;
  final String address;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RoutesBuilderState {
  const RoutesBuilderState({
    this.sellers = const [],
    this.unassignedClients = const [],
    this.assignments = const {},
    this.selectedSellerId,
    this.routeDate,
    this.isLoading = true,
  });

  final List<_SellerItem> sellers;
  final List<_ClientItem> unassignedClients;
  final Map<String, List<_ClientItem>> assignments; // sellerId -> clients
  final String? selectedSellerId;
  final DateTime? routeDate;
  final bool isLoading;

  RoutesBuilderState copyWith({
    List<_SellerItem>? sellers,
    List<_ClientItem>? unassignedClients,
    Map<String, List<_ClientItem>>? assignments,
    String? selectedSellerId,
    DateTime? routeDate,
    bool? isLoading,
  }) {
    return RoutesBuilderState(
      sellers: sellers ?? this.sellers,
      unassignedClients: unassignedClients ?? this.unassignedClients,
      assignments: assignments ?? this.assignments,
      selectedSellerId: selectedSellerId ?? this.selectedSellerId,
      routeDate: routeDate ?? this.routeDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class RoutesBuilderCubit extends Cubit<RoutesBuilderState> {
  RoutesBuilderCubit() : super(const RoutesBuilderState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final sellers = List.generate(
      6,
      (i) => _SellerItem('s$i', 'Vendedor ${i + 1}'),
    );
    final clients = List.generate(
      20,
      (i) => _ClientItem('c$i', 'Cliente ${i + 1}', 'Rua ${i + 1}, ${100 + i}'),
    );

    emit(state.copyWith(
      sellers: sellers,
      unassignedClients: clients,
      assignments: {for (final s in sellers) s.id: <_ClientItem>[]},
      routeDate: DateTime.now(),
      isLoading: false,
    ));
  }

  void selectSeller(String id) {
    emit(state.copyWith(selectedSellerId: id));
  }

  void setDate(DateTime date) {
    emit(state.copyWith(routeDate: date));
  }

  void assignClient(String clientId, String sellerId) {
    final client =
        state.unassignedClients.where((c) => c.id == clientId).firstOrNull;
    if (client == null) return;

    final unassigned =
        state.unassignedClients.where((c) => c.id != clientId).toList();
    final assignments = Map<String, List<_ClientItem>>.from(state.assignments);
    assignments[sellerId] = [...(assignments[sellerId] ?? []), client];

    emit(state.copyWith(
      unassignedClients: unassigned,
      assignments: assignments,
    ));
  }

  void unassignClient(String clientId, String sellerId) {
    final assignments = Map<String, List<_ClientItem>>.from(state.assignments);
    final list = List<_ClientItem>.from(assignments[sellerId] ?? []);
    final client = list.where((c) => c.id == clientId).firstOrNull;
    if (client == null) return;

    list.removeWhere((c) => c.id == clientId);
    assignments[sellerId] = list;

    emit(state.copyWith(
      unassignedClients: [...state.unassignedClients, client],
      assignments: assignments,
    ));
  }

  void clearAll() {
    final allClients = <_ClientItem>[];
    for (final list in state.assignments.values) {
      allClients.addAll(list);
    }
    allClients.addAll(state.unassignedClients);

    final assignments = Map<String, List<_ClientItem>>.from(state.assignments);
    for (final key in assignments.keys) {
      assignments[key] = [];
    }

    emit(state.copyWith(
      unassignedClients: allClients,
      assignments: assignments,
    ));
  }

  Future<void> save() async {
    // TODO: persist route assignments via API
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RoutesBuilderScreen extends StatelessWidget {
  const RoutesBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoutesBuilderCubit()..load(),
      child: const _RoutesBuilderBody(),
    );
  }
}

class _RoutesBuilderBody extends StatelessWidget {
  const _RoutesBuilderBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesBuilderCubit, RoutesBuilderState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text('Montagem de Rotas',
                            style: AppTypography.displayMedium),
                      ),
                      _DatePickerButton(date: state.routeDate),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Two-panel layout
                  if (isWide)
                    SizedBox(
                      height: 600,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left panel: sellers
                          SizedBox(
                            width: 280,
                            child: _SellerListPanel(
                              sellers: state.sellers,
                              selectedId: state.selectedSellerId,
                              assignments: state.assignments,
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right panel: assignment area
                          Expanded(
                            child: _AssignmentPanel(
                              state: state,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _SellerListPanel(
                      sellers: state.sellers,
                      selectedId: state.selectedSellerId,
                      assignments: state.assignments,
                    ),
                    const SizedBox(height: 24),
                    _AssignmentPanel(state: state),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            context.read<RoutesBuilderCubit>().clearAll(),
                        child: const Text('Limpar Tudo'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        onPressed: () =>
                            context.read<RoutesBuilderCubit>().save(),
                        child: const Text('Salvar Rotas'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Date picker
// ---------------------------------------------------------------------------

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final formatted = date != null
        ? DateFormat('dd/MM/yyyy').format(date!)
        : 'Selecionar data';

    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(formatted),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && context.mounted) {
          context.read<RoutesBuilderCubit>().setDate(picked);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Seller list panel (left)
// ---------------------------------------------------------------------------

class _SellerListPanel extends StatelessWidget {
  const _SellerListPanel({
    required this.sellers,
    required this.selectedId,
    required this.assignments,
  });

  final List<_SellerItem> sellers;
  final String? selectedId;
  final Map<String, List<_ClientItem>> assignments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Vendedores',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              itemCount: sellers.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final s = sellers[i];
                final count = (assignments[s.id] ?? []).length;
                final selected = s.id == selectedId;

                return ListTile(
                  selected: selected,
                  selectedTileColor: AppColors.accent,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      s.name[0],
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  title: Text(s.name, style: AppTypography.bodyMedium),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text('$count', style: AppTypography.label),
                  ),
                  onTap: () =>
                      context.read<RoutesBuilderCubit>().selectSeller(s.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assignment panel (right)
// ---------------------------------------------------------------------------

class _AssignmentPanel extends StatelessWidget {
  const _AssignmentPanel({required this.state});
  final RoutesBuilderState state;

  @override
  Widget build(BuildContext context) {
    final sellerId = state.selectedSellerId;
    final assigned = sellerId != null ? (state.assignments[sellerId] ?? []) : <_ClientItem>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assigned clients header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              sellerId != null
                  ? 'Clientes atribuídos'
                  : 'Selecione um vendedor',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Drop target for assigned
          if (sellerId != null)
            Expanded(
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  context
                      .read<RoutesBuilderCubit>()
                      .assignClient(details.data, sellerId);
                },
                builder: (context, candidateData, rejectedData) {
                  final highlighted = candidateData.isNotEmpty;
                  return Container(
                    color:
                        highlighted ? AppColors.accent : Colors.transparent,
                    child: assigned.isEmpty
                        ? Center(
                            child: Text(
                              'Arraste clientes aqui',
                              style: AppTypography.label,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: assigned.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, i) {
                              final c = assigned[i];
                              return _ClientTile(
                                client: c,
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  color: AppColors.mutedForeground,
                                  onPressed: () => context
                                      .read<RoutesBuilderCubit>()
                                      .unassignClient(c.id, sellerId),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            )
          else
            const Expanded(child: SizedBox()),

          // Unassigned pool
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Clientes disponíveis (${state.unassignedClients.length})',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: state.unassignedClients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final c = state.unassignedClients[i];
                return Draggable<String>(
                  data: c.id,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: AppRadius.mdBorder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Text(c.name, style: AppTypography.bodyMedium),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: _ClientTile(client: c),
                  ),
                  child: _ClientTile(client: c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client tile
// ---------------------------------------------------------------------------

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client, this.trailing});
  final _ClientItem client;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name, style: AppTypography.bodyMedium),
                Text(client.address, style: AppTypography.label),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
