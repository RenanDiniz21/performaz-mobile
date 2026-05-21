import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProductCatalogState extends Equatable {
  const ProductCatalogState({
    this.products = const [],
    this.filteredProducts = const [],
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery = '',
  });

  final List<Product> products;
  final List<Product> filteredProducts;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;

  ProductCatalogState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool clearCategory = false,
  }) {
    return ProductCatalogState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props =>
      [products, filteredProducts, categories, selectedCategory, searchQuery];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class ProductCatalogCubit extends Cubit<ProductCatalogState> {
  ProductCatalogCubit() : super(const ProductCatalogState());

  void loadProducts(List<Product> products) {
    final activeProducts = products.where((p) => p.isActive).toList();
    final categories = activeProducts
        .map((p) => p.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    emit(state.copyWith(
      products: activeProducts,
      filteredProducts: activeProducts,
      categories: categories,
    ));
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  void selectCategory(String? category) {
    if (category == state.selectedCategory) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategory: category));
    }
    _applyFilters();
  }

  void _applyFilters() {
    var result = state.products;

    if (state.selectedCategory != null) {
      result =
          result.where((p) => p.category == state.selectedCategory).toList();
    }

    final q = state.searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.code?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    emit(state.copyWith(filteredProducts: result));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key, required this.onProductSelected});

  final ValueChanged<Product> onProductSelected;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ProductCatalogCubit>().search(value);
    });
  }

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Produtos', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: DotGridBackground(
        child: BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
          builder: (context, state) {
            return Column(
              children: [
                // Search
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTypography.body(14),
                    decoration: InputDecoration(
                      hintText: 'Buscar produto...',
                      prefixIcon: Icon(Icons.search, color: mutedFg),
                    ),
                  ),
                ),

                // Category chips
                if (state.categories.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = state.categories[index];
                        final isSelected = cat == state.selectedCategory;
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => context
                              .read<ProductCatalogCubit>()
                              .selectCategory(cat),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                // Product list
                Expanded(
                  child: state.filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: mutedFg.withValues(alpha: 0.4)),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum produto encontrado',
                                style: AppTypography.body(16).copyWith(color: mutedFg),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: state.filteredProducts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = state.filteredProducts[index];
                            return _ProductTile(
                              product: product,
                              onTap: () =>
                                  widget.onProductSelected(product),
                              formatPrice: _formatPrice,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product tile
// ---------------------------------------------------------------------------

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.formatPrice,
  });

  final Product product;
  final VoidCallback onTap;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final mutedBg = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.body(15, weight: FontWeight.w600).copyWith(color: fgColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatPrice(product.unitPrice)} / ${product.unitOfMeasure}',
                    style: AppTypography.body(13).copyWith(color: mutedFg),
                  ),
                  if (product.category != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: mutedBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        product.category!,
                        style: AppTypography.body(12, weight: FontWeight.w500).copyWith(color: mutedFg),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
          ],
        ),
      ),
    );
  }
}
