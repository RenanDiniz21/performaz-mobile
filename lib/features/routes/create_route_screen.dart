import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../core/repositories/crud_repository.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/models/client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';
import 'route_cubit.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum CreateRoutePhase { loading, picking, submitting, error }

class CreateRouteState extends Equatable {
  const CreateRouteState({
    this.phase = CreateRoutePhase.loading,
    this.allClients = const [],
    this.filteredClients = const [],
    this.selectedClients = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final CreateRoutePhase phase;
  final List<Client> allClients;
  final List<Client> filteredClients;
  final List<Client> selectedClients;
  final String searchQuery;
  final String? errorMessage;

  bool get canSubmit => selectedClients.isNotEmpty;

  CreateRouteState copyWith({
    CreateRoutePhase? phase,
    List<Client>? allClients,
    List<Client>? filteredClients,
    List<Client>? selectedClients,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CreateRouteState(
      phase: phase ?? this.phase,
      allClients: allClients ?? this.allClients,
      filteredClients: filteredClients ?? this.filteredClients,
      selectedClients: selectedClients ?? this.selectedClients,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        allClients,
        filteredClients,
        selectedClients,
        searchQuery,
        errorMessage,
      ];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class CreateRouteCubit extends Cubit<CreateRouteState> {
  CreateRouteCubit({
    required this.apiClient,
    required this.crudRepository,
    required this.secureStorage,
  }) : super(const CreateRouteState());

  final ApiClient apiClient;
  final CrudRepository crudRepository;
  final SecureStorage secureStorage;

  Future<void> loadClients() async {
    emit(state.copyWith(phase: CreateRoutePhase.loading));
    try {
      final rows = await crudRepository.fetchClients();
      final clients = rows.map(Client.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        phase: CreateRoutePhase.picking,
        allClients: clients,
        filteredClients: clients,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: CreateRoutePhase.error,
        errorMessage: 'Erro ao carregar clientes: $e',
      ));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilter();
  }

  void _applyFilter() {
    final q = state.searchQuery.toLowerCase();
    if (q.isEmpty) {
      emit(state.copyWith(filteredClients: state.allClients));
      return;
    }
    emit(state.copyWith(
      filteredClients: state.allClients
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.cnpj.contains(q) ||
              c.address.toLowerCase().contains(q))
          .toList(),
    ));
  }

  void toggleClient(Client client) {
    final selected = List<Client>.from(state.selectedClients);
    final index = selected.indexWhere((c) => c.id == client.id);
    if (index >= 0) {
      selected.removeAt(index);
    } else {
      selected.add(client);
    }
    emit(state.copyWith(selectedClients: selected));
  }

  bool isSelected(String clientId) {
    return state.selectedClients.any((c) => c.id == clientId);
  }

  void reorderSelected(int oldIndex, int newIndex) {
    final selected = List<Client>.from(state.selectedClients);
    final item = selected.removeAt(oldIndex);
    selected.insert(newIndex, item);
    emit(state.copyWith(selectedClients: selected));
  }

  void removeSelected(String clientId) {
    final selected =
        state.selectedClients.where((c) => c.id != clientId).toList();
    emit(state.copyWith(selectedClients: selected));
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    emit(state.copyWith(phase: CreateRoutePhase.submitting));
    try {
      final vendorId = await secureStorage.getUserId();
      if (vendorId == null) {
        emit(state.copyWith(
          phase: CreateRoutePhase.picking,
          errorMessage: 'Usuário não autenticado',
        ));
        return false;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final clients = state.selectedClients.indexed
          .map((e) => {'clientId': e.$2.id, 'order': e.$1 + 1})
          .toList();

      await apiClient.post('/routes', data: {
        'vendorId': vendorId,
        'date': today,
        'clients': clients,
      });

      return true;
    } catch (e) {
      emit(state.copyWith(
        phase: CreateRoutePhase.picking,
        errorMessage: 'Erro ao criar rota: $e',
      ));
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CreateRouteScreen extends StatelessWidget {
  const CreateRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateRouteCubit(
        apiClient: getIt<ApiClient>(),
        crudRepository: getIt<CrudRepository>(),
        secureStorage: getIt<SecureStorage>(),
      )..loadClients(),
      child: const _CreateRouteBody(),
    );
  }
}

class _CreateRouteBody extends StatefulWidget {
  const _CreateRouteBody();

  @override
  State<_CreateRouteBody> createState() => _CreateRouteBodyState();
}

class _CreateRouteBodyState extends State<_CreateRouteBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<CreateRouteCubit>().search(value);
    });
  }

  Future<void> _onSubmit() async {
    final cubit = context.read<CreateRouteCubit>();
    final success = await cubit.submit();
    if (success && mounted) {
      context.read<RouteCubit>().loadRoute();
      context.go('/routes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Criar Rota', style: AppTypography.title(20)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: mutedFg,
          indicatorColor: primaryColor,
          labelStyle: AppTypography.body(14, weight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Clientes'),
            Tab(text: 'Ordem'),
          ],
        ),
      ),
      body: BlocBuilder<CreateRouteCubit, CreateRouteState>(
        builder: (context, state) {
          if (state.phase == CreateRoutePhase.loading) {
            return Center(
                child: CircularProgressIndicator(color: primaryColor));
          }

          if (state.phase == CreateRoutePhase.error &&
              state.allClients.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: AppColors.statusError),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? 'Erro desconhecido',
                    style: AppTypography.body(14).copyWith(color: mutedFg),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<CreateRouteCubit>().loadClients(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final cubit = context.read<CreateRouteCubit>();

          return Column(
            children: [
              // Error banner
              if (state.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.statusError.withValues(alpha: 0.1),
                  child: Text(
                    state.errorMessage!,
                    style: AppTypography.body(13)
                        .copyWith(color: AppColors.statusError),
                  ),
                ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- Tab 1: Client picker ---
                    DotGridBackground(
                      child: Column(
                        children: [
                          // Search
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: AppTypography.body(14),
                              decoration: InputDecoration(
                                hintText: 'Buscar cliente...',
                                hintStyle: AppTypography.body(14)
                                    .copyWith(color: mutedFg),
                                prefixIcon:
                                    Icon(Icons.search, color: mutedFg),
                                filled: true,
                                fillColor: cardColor,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide:
                                      BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ),

                          // Selected count
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  '${state.selectedClients.length} selecionado(s)',
                                  style: AppTypography.body(13,
                                          weight: FontWeight.w600)
                                      .copyWith(color: primaryColor),
                                ),
                                const Spacer(),
                                Text(
                                  '${state.filteredClients.length} clientes',
                                  style: AppTypography.body(12)
                                      .copyWith(color: mutedFg),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Client list
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: state.filteredClients.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final client = state.filteredClients[index];
                                final selected = cubit.isSelected(client.id);
                                return _ClientPickerTile(
                                  client: client,
                                  isSelected: selected,
                                  onTap: () => cubit.toggleClient(client),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Tab 2: Order selected ---
                    DotGridBackground(
                      child: state.selectedClients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_outlined,
                                      size: 48,
                                      color: mutedFg.withValues(alpha: 0.4)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Selecione clientes na aba anterior',
                                    style: AppTypography.body(14)
                                        .copyWith(color: mutedFg),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.drag_indicator,
                                          size: 18, color: mutedFg),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Arraste para reordenar',
                                        style: AppTypography.body(13)
                                            .copyWith(color: mutedFg),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ReorderableListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    buildDefaultDragHandles: true,
                                    itemCount: state.selectedClients.length,
                                    onReorder: (oldIndex, newIndex) {
                                      cubit.reorderSelected(
                                        oldIndex,
                                        newIndex > oldIndex
                                            ? newIndex - 1
                                            : newIndex,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final client =
                                          state.selectedClients[index];
                                      return Padding(
                                        key: ValueKey(client.id),
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: _OrderedClientTile(
                                          client: client,
                                          index: index,
                                          onRemove: () =>
                                              cubit.removeSelected(client.id),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              // Bottom submit bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: state.phase == CreateRoutePhase.submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 20),
                      label: Text(
                        state.selectedClients.isEmpty
                            ? 'Selecione clientes'
                            : 'Criar Rota (${state.selectedClients.length} paradas)',
                        style:
                            AppTypography.body(15, weight: FontWeight.w600),
                      ),
                      onPressed: state.canSubmit &&
                              state.phase != CreateRoutePhase.submitting
                          ? _onSubmit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            primaryColor.withValues(alpha: 0.3),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
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
// Client picker tile
// ---------------------------------------------------------------------------

class _ClientPickerTile extends StatelessWidget {
  const _ClientPickerTile({
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  final Client client;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isSelected
          ? primaryColor.withValues(alpha: 0.08)
          : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: isSelected ? primaryColor : mutedFg,
                width: isSelected ? 0 : 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: AppTypography.body(14, weight: FontWeight.w600)
                      .copyWith(color: fgColor),
                ),
                const SizedBox(height: 2),
                Text(
                  client.address,
                  style: AppTypography.body(12).copyWith(color: mutedFg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (client.phone != null && client.phone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.phone_outlined, size: 16, color: mutedFg),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ordered client tile (reorderable)
// ---------------------------------------------------------------------------

class _OrderedClientTile extends StatelessWidget {
  const _OrderedClientTile({
    required this.client,
    required this.index,
    required this.onRemove,
  });

  final Client client;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${index + 1}',
              style: AppTypography.body(14, weight: FontWeight.w700)
                  .copyWith(color: primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: AppTypography.body(14, weight: FontWeight.w600)
                      .copyWith(color: fgColor),
                ),
                Text(
                  client.address,
                  style: AppTypography.body(12).copyWith(color: mutedFg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: mutedFg),
            visualDensity: VisualDensity.compact,
          ),
          Icon(Icons.drag_handle, color: mutedFg, size: 20),
        ],
      ),
    );
  }
}
