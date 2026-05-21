import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ProductRow {
  _ProductRow({
    required this.id,
    required this.name,
    required this.code,
    required this.unitPrice,
    required this.unit,
    required this.category,
    this.isActive = true,
  });

  final String id;
  String name;
  String code;
  double unitPrice;
  String unit;
  String category;
  bool isActive;
}

class ProductsCrudState {
  const ProductsCrudState({
    this.products = const [],
    this.filtered = const [],
    this.query = '',
    this.sortColumn = 0,
    this.sortAsc = true,
    this.page = 0,
    this.rowsPerPage = 10,
    this.isLoading = true,
  });

  final List<_ProductRow> products;
  final List<_ProductRow> filtered;
  final String query;
  final int sortColumn;
  final bool sortAsc;
  final int page;
  final int rowsPerPage;
  final bool isLoading;

  int get totalPages => (filtered.length / rowsPerPage).ceil().clamp(1, 9999);

  List<_ProductRow> get pageItems {
    final start = page * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  ProductsCrudState copyWith({
    List<_ProductRow>? products,
    List<_ProductRow>? filtered,
    String? query,
    int? sortColumn,
    bool? sortAsc,
    int? page,
    int? rowsPerPage,
    bool? isLoading,
  }) {
    return ProductsCrudState(
      products: products ?? this.products,
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

class ProductsCrudCubit extends Cubit<ProductsCrudState> {
  ProductsCrudCubit() : super(const ProductsCrudState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final categories = ['Bebidas', 'Laticínios', 'Frios', 'Mercearia', 'Limpeza'];
    final units = ['UN', 'CX', 'KG', 'L', 'PCT'];
    final mock = List.generate(
      40,
      (i) => _ProductRow(
        id: 'p$i',
        name: 'Produto ${i + 1}',
        code: 'PRD-${1000 + i}',
        unitPrice: 5.0 + (i * 2.5),
        unit: units[i % units.length],
        category: categories[i % categories.length],
        isActive: i % 6 != 0,
      ),
    );
    emit(state.copyWith(products: mock, filtered: mock, isLoading: false));
  }

  void search(String query) {
    final q = query.toLowerCase();
    final filtered = state.products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
    emit(state.copyWith(query: query, filtered: filtered, page: 0));
  }

  void sort(int column, bool asc) {
    final list = List<_ProductRow>.from(state.filtered);
    list.sort((a, b) {
      final cmp = switch (column) {
        0 => a.name.compareTo(b.name),
        1 => a.code.compareTo(b.code),
        2 => a.unitPrice.compareTo(b.unitPrice),
        3 => a.unit.compareTo(b.unit),
        4 => a.category.compareTo(b.category),
        5 => a.isActive == b.isActive ? 0 : (a.isActive ? -1 : 1),
        _ => 0,
      };
      return asc ? cmp : -cmp;
    });
    emit(state.copyWith(filtered: list, sortColumn: column, sortAsc: asc));
  }

  void setPage(int page) => emit(state.copyWith(page: page));

  void delete(String id) {
    final products = state.products.where((p) => p.id != id).toList();
    final filtered = state.filtered.where((p) => p.id != id).toList();
    emit(state.copyWith(products: products, filtered: filtered));
  }

  void addOrUpdate(_ProductRow product) {
    final products = List<_ProductRow>.from(state.products);
    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      products[idx] = product;
    } else {
      products.add(product);
    }
    emit(state.copyWith(products: products, filtered: products));
    search(state.query);
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProductsCrudScreen extends StatelessWidget {
  const ProductsCrudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCrudCubit()..load(),
      child: const _ProductsCrudBody(),
    );
  }
}

class _ProductsCrudBody extends StatelessWidget {
  const _ProductsCrudBody();

  static final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCrudCubit, ProductsCrudState>(
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
                  Text('Produtos', style: AppTypography.displayMedium),
                  const SizedBox(height: 20),

                  _Toolbar(
                    query: state.query,
                    onAdd: () {
                      _showEditDialog(
                        context,
                        _ProductRow(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: '',
                          code: '',
                          unitPrice: 0.0,
                          unit: '',
                          category: '',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

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
                                context.read<ProductsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Código'),
                            onSort: (i, asc) =>
                                context.read<ProductsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Preço Unitário'),
                            numeric: true,
                            onSort: (i, asc) =>
                                context.read<ProductsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Unidade'),
                            onSort: (i, asc) =>
                                context.read<ProductsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Categoria'),
                            onSort: (i, asc) =>
                                context.read<ProductsCrudCubit>().sort(i, asc),
                          ),
                          DataColumn(
                            label: const Text('Status'),
                            onSort: (i, asc) =>
                                context.read<ProductsCrudCubit>().sort(i, asc),
                          ),
                          const DataColumn(label: Text('Ações')),
                        ],
                        rows: state.pageItems.map((p) {
                          return DataRow(
                            color: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.hovered)
                                  ? AppColors.accent
                                  : null,
                            ),
                            cells: [
                              DataCell(Text(p.name)),
                              DataCell(Text(p.code)),
                              DataCell(
                                  Text(_currencyFormat.format(p.unitPrice))),
                              DataCell(Text(p.unit)),
                              DataCell(Text(p.category)),
                              DataCell(_StatusChip(active: p.isActive)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    color: AppColors.mutedForeground,
                                    onPressed: () =>
                                        _showEditDialog(context, p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    color: AppColors.destructive,
                                    onPressed: () => context
                                        .read<ProductsCrudCubit>()
                                        .delete(p.id),
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

                  _Pagination(
                    page: state.page,
                    totalPages: state.totalPages,
                    onChanged: (p) =>
                        context.read<ProductsCrudCubit>().setPage(p),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, _ProductRow product) {
    final nameCtrl = TextEditingController(text: product.name);
    final codeCtrl = TextEditingController(text: product.code);
    final priceCtrl =
        TextEditingController(text: product.unitPrice.toStringAsFixed(2));
    final unitCtrl = TextEditingController(text: product.unit);
    final catCtrl = TextEditingController(text: product.category);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Produto', style: AppTypography.displaySmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Código'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Preço Unitário'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Unidade'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(labelText: 'Categoria'),
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
              product
                ..name = nameCtrl.text
                ..code = codeCtrl.text
                ..unitPrice = double.tryParse(priceCtrl.text) ?? product.unitPrice
                ..unit = unitCtrl.text
                ..category = catCtrl.text;
              context.read<ProductsCrudCubit>().addOrUpdate(product);
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
  const _Toolbar({required this.query, required this.onAdd});
  final String query;
  final VoidCallback onAdd;

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
            onChanged: (v) => context.read<ProductsCrudCubit>().search(v),
            decoration: InputDecoration(
              hintText: 'Buscar produto...',
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
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Adicionar'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Importação de CSV iniciada')),
            );
          },
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Importar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exportação de CSV iniciada')),
            );
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
