import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _Seller {
  _Seller({
    required this.id,
    required this.name,
    required this.email,
    required this.matricula,
    this.isActive = true,
  });

  final String id;
  String name;
  String email;
  String matricula;
  bool isActive;
}

class SellersCrudState {
  const SellersCrudState({
    this.sellers = const [],
    this.filtered = const [],
    this.query = '',
    this.sortColumn = 0,
    this.sortAsc = true,
    this.page = 0,
    this.rowsPerPage = 10,
    this.isLoading = true,
  });

  final List<_Seller> sellers;
  final List<_Seller> filtered;
  final String query;
  final int sortColumn;
  final bool sortAsc;
  final int page;
  final int rowsPerPage;
  final bool isLoading;

  int get totalPages => (filtered.length / rowsPerPage).ceil().clamp(1, 9999);

  List<_Seller> get pageItems {
    final start = page * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  SellersCrudState copyWith({
    List<_Seller>? sellers,
    List<_Seller>? filtered,
    String? query,
    int? sortColumn,
    bool? sortAsc,
    int? page,
    int? rowsPerPage,
    bool? isLoading,
  }) {
    return SellersCrudState(
      sellers: sellers ?? this.sellers,
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

class SellersCrudCubit extends Cubit<SellersCrudState> {
  SellersCrudCubit() : super(const SellersCrudState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // TODO: replace with API
    final mock = List.generate(
      25,
      (i) => _Seller(
        id: 'v$i',
        name: 'Vendedor ${i + 1}',
        email: 'vendedor${i + 1}@performaz.com',
        matricula: '${1000 + i}',
        isActive: i % 5 != 0,
      ),
    );
    emit(state.copyWith(sellers: mock, filtered: mock, isLoading: false));
  }

  void search(String query) {
    final q = query.toLowerCase();
    final filtered = state.sellers
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.matricula.contains(q))
        .toList();
    emit(state.copyWith(query: query, filtered: filtered, page: 0));
  }

  void sort(int column, bool asc) {
    final list = List<_Seller>.from(state.filtered);
    list.sort((a, b) {
      final cmp = switch (column) {
        0 => a.name.compareTo(b.name),
        1 => a.email.compareTo(b.email),
        2 => a.matricula.compareTo(b.matricula),
        3 => a.isActive == b.isActive
            ? 0
            : (a.isActive ? -1 : 1),
        _ => 0,
      };
      return asc ? cmp : -cmp;
    });
    emit(state.copyWith(filtered: list, sortColumn: column, sortAsc: asc));
  }

  void setPage(int page) => emit(state.copyWith(page: page));

  void delete(String id) {
    final sellers = state.sellers.where((s) => s.id != id).toList();
    final filtered = state.filtered.where((s) => s.id != id).toList();
    emit(state.copyWith(sellers: sellers, filtered: filtered));
  }

  void addOrUpdate(_Seller seller) {
    final sellers = List<_Seller>.from(state.sellers);
    final idx = sellers.indexWhere((s) => s.id == seller.id);
    if (idx >= 0) {
      sellers[idx] = seller;
    } else {
      sellers.add(seller);
    }
    emit(state.copyWith(sellers: sellers, filtered: sellers));
    search(state.query);
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SellersCrudScreen extends StatelessWidget {
  const SellersCrudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SellersCrudCubit()..load(),
      child: const _SellersCrudBody(),
    );
  }
}

class _SellersCrudBody extends StatelessWidget {
  const _SellersCrudBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellersCrudCubit, SellersCrudState>(
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
                  // Header
                  Text('Vendedores', style: AppTypography.displayMedium),
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
                                context.read<SellersCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('E-mail'),
                            onSort: (i, asc) =>
                                context.read<SellersCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Matrícula'),
                            onSort: (i, asc) =>
                                context.read<SellersCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Status'),
                            onSort: (i, asc) =>
                                context.read<SellersCrudCubit>().sort(i, asc),
                          ),
                          const DataColumn(label: Text('Ações')),
                        ],
                        rows: state.pageItems.map((s) {
                          return DataRow(
                            color: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.hovered)
                                  ? AppColors.accent
                                  : null,
                            ),
                            cells: [
                              DataCell(Text(s.name)),
                              DataCell(Text(s.email)),
                              DataCell(Text(s.matricula)),
                              DataCell(_StatusChip(active: s.isActive)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    color: AppColors.mutedForeground,
                                    onPressed: () => _showEditDialog(
                                        context, s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    color: AppColors.destructive,
                                    onPressed: () => context
                                        .read<SellersCrudCubit>()
                                        .delete(s.id),
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
                        context.read<SellersCrudCubit>().setPage(p),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, _Seller seller) {
    final nameCtrl = TextEditingController(text: seller.name);
    final emailCtrl = TextEditingController(text: seller.email);
    final matCtrl = TextEditingController(text: seller.matricula);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Vendedor', style: AppTypography.displaySmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: matCtrl,
              decoration: const InputDecoration(labelText: 'Matrícula'),
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
              seller
                ..name = nameCtrl.text
                ..email = emailCtrl.text
                ..matricula = matCtrl.text;
              context.read<SellersCrudCubit>().addOrUpdate(seller);
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
// Toolbar
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
            onChanged: (v) => context.read<SellersCrudCubit>().search(v),
            decoration: InputDecoration(
              hintText: 'Buscar vendedor...',
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
            // TODO: add new seller dialog
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

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

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
