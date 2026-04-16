import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ClientRow {
  _ClientRow({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.address,
    required this.assignedSeller,
    this.isActive = true,
  });

  final String id;
  String name;
  String cnpj;
  String address;
  String assignedSeller;
  bool isActive;
}

class ClientsCrudState {
  const ClientsCrudState({
    this.clients = const [],
    this.filtered = const [],
    this.query = '',
    this.sortColumn = 0,
    this.sortAsc = true,
    this.page = 0,
    this.rowsPerPage = 10,
    this.isLoading = true,
  });

  final List<_ClientRow> clients;
  final List<_ClientRow> filtered;
  final String query;
  final int sortColumn;
  final bool sortAsc;
  final int page;
  final int rowsPerPage;
  final bool isLoading;

  int get totalPages => (filtered.length / rowsPerPage).ceil().clamp(1, 9999);

  List<_ClientRow> get pageItems {
    final start = page * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  ClientsCrudState copyWith({
    List<_ClientRow>? clients,
    List<_ClientRow>? filtered,
    String? query,
    int? sortColumn,
    bool? sortAsc,
    int? page,
    int? rowsPerPage,
    bool? isLoading,
  }) {
    return ClientsCrudState(
      clients: clients ?? this.clients,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAsc: sortAsc ?? this.sortAsc,
      page: page ?? this.page,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class ClientsCrudCubit extends Cubit<ClientsCrudState> {
  ClientsCrudCubit() : super(const ClientsCrudState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final sellers = ['Carlos Silva', 'Ana Ferreira', 'Pedro Souza', 'Julia Lima'];
    final mock = List.generate(
      30,
      (i) => _ClientRow(
        id: 'c$i',
        name: 'Cliente ${i + 1}',
        cnpj: '${10 + i}.${200 + i}.${300 + i}/0001-${10 + i}',
        address: 'Rua Exemplo ${i + 1}, ${100 + i}',
        assignedSeller: sellers[i % sellers.length],
        isActive: i % 4 != 0,
      ),
    );
    emit(state.copyWith(clients: mock, filtered: mock, isLoading: false));
  }

  void search(String query) {
    final q = query.toLowerCase();
    final filtered = state.clients
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.cnpj.contains(q) ||
            c.assignedSeller.toLowerCase().contains(q))
        .toList();
    emit(state.copyWith(query: query, filtered: filtered, page: 0));
  }

  void sort(int column, bool asc) {
    final list = List<_ClientRow>.from(state.filtered);
    list.sort((a, b) {
      final cmp = switch (column) {
        0 => a.name.compareTo(b.name),
        1 => a.cnpj.compareTo(b.cnpj),
        2 => a.address.compareTo(b.address),
        3 => a.assignedSeller.compareTo(b.assignedSeller),
        4 => a.isActive == b.isActive ? 0 : (a.isActive ? -1 : 1),
        _ => 0,
      };
      return asc ? cmp : -cmp;
    });
    emit(state.copyWith(filtered: list, sortColumn: column, sortAsc: asc));
  }

  void setPage(int page) => emit(state.copyWith(page: page));

  void delete(String id) {
    final clients = state.clients.where((c) => c.id != id).toList();
    final filtered = state.filtered.where((c) => c.id != id).toList();
    emit(state.copyWith(clients: clients, filtered: filtered));
  }

  void addOrUpdate(_ClientRow client) {
    final clients = List<_ClientRow>.from(state.clients);
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) {
      clients[idx] = client;
    } else {
      clients.add(client);
    }
    emit(state.copyWith(clients: clients, filtered: clients));
    search(state.query);
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ClientsCrudScreen extends StatelessWidget {
  const ClientsCrudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientsCrudCubit()..load(),
      child: const _ClientsCrudBody(),
    );
  }
}

class _ClientsCrudBody extends StatelessWidget {
  const _ClientsCrudBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCrudCubit, ClientsCrudState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clientes', style: AppTypography.displayMedium),
                  const SizedBox(height: 20),

                  // Toolbar
                  _Toolbar(query: state.query),
                  const SizedBox(height: 16),

                  // Table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        sortColumnIndex: state.sortColumn,
                        sortAscending: state.sortAsc,
                        headingRowColor:
                            WidgetStateProperty.all(AppColors.muted),
                        headingTextStyle: AppTypography.label
                            .copyWith(fontWeight: FontWeight.w600),
                        dataTextStyle: AppTypography.bodyMedium,
                        columns: [
                          DataColumn(
                            label: const Text('Nome'),
                            onSort: (i, asc) =>
                                context.read<ClientsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('CNPJ'),
                            onSort: (i, asc) =>
                                context.read<ClientsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Endereço'),
                            onSort: (i, asc) =>
                                context.read<ClientsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Vendedor Atribuído'),
                            onSort: (i, asc) =>
                                context.read<ClientsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Status'),
                            onSort: (i, asc) =>
                                context.read<ClientsCrudCubit>().sort(i, asc),
                          ),
                          const DataColumn(label: Text('Ações')),
                        ],
                        rows: state.pageItems.map((c) {
                          return DataRow(
                            color: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.hovered)
                                  ? AppColors.accent
                                  : null,
                            ),
                            cells: [
                              DataCell(Text(c.name)),
                              DataCell(Text(c.cnpj)),
                              DataCell(
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  child: Text(c.address,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              DataCell(Text(c.assignedSeller)),
                              DataCell(_StatusChip(active: c.isActive)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    color: AppColors.mutedForeground,
                                    onPressed: () =>
                                        _showEditDialog(context, c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    color: AppColors.destructive,
                                    onPressed: () => context
                                        .read<ClientsCrudCubit>()
                                        .delete(c.id),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pagination
                  _Pagination(
                    page: state.page,
                    totalPages: state.totalPages,
                    onChanged: (p) =>
                        context.read<ClientsCrudCubit>().setPage(p),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, _ClientRow client) {
    final nameCtrl = TextEditingController(text: client.name);
    final cnpjCtrl = TextEditingController(text: client.cnpj);
    final addrCtrl = TextEditingController(text: client.address);
    final sellerCtrl = TextEditingController(text: client.assignedSeller);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Cliente', style: AppTypography.displaySmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cnpjCtrl,
              decoration: const InputDecoration(labelText: 'CNPJ'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sellerCtrl,
              decoration:
                  const InputDecoration(labelText: 'Vendedor Atribuído'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              client
                ..name = nameCtrl.text
                ..cnpj = cnpjCtrl.text
                ..address = addrCtrl.text
                ..assignedSeller = sellerCtrl.text;
              context.read<ClientsCrudCubit>().addOrUpdate(client);
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (v) => context.read<ClientsCrudCubit>().search(v),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              hintStyle: AppTypography.label,
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.mutedForeground),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdBorder,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            // TODO: add new client dialog
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Adicionar'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: CSV import
          },
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Importar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: CSV export
          },
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Exportar CSV'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.successBg : AppColors.muted,
        borderRadius: AppRadius.smBorder,
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: AppTypography.bodySmall.copyWith(
          color: active ? AppColors.success : AppColors.mutedForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: page > 0 ? () => onChanged(page - 1) : null,
        ),
        Text(
          'Página ${page + 1} de $totalPages',
          style: AppTypography.bodyMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              page < totalPages - 1 ? () => onChanged(page + 1) : null,
        ),
      ],
    );
  }
}
