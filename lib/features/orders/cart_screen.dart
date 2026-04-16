import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/order.dart';
import '../../shared/models/product.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.notes = '',
  });

  final List<OrderItem> items;
  final String notes;

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<OrderItem>? items,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [items, notes];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addProduct(Product product) {
    final existing = state.items.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      final updated = List<OrderItem>.from(state.items);
      updated[existing] =
          updated[existing].copyWith(quantity: updated[existing].quantity + 1);
      emit(state.copyWith(items: updated));
    } else {
      emit(state.copyWith(
        items: [...state.items, OrderItem(product: product, quantity: 1)],
      ));
    }
  }

  void increment(String productId) {
    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void decrement(String productId) {
    final updated = state.items.map((item) {
      if (item.product.id == productId && item.quantity > 1) {
        return item.copyWith(quantity: item.quantity - 1);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void removeItem(String productId) {
    final updated =
        state.items.where((i) => i.product.id != productId).toList();
    emit(state.copyWith(items: updated));
  }

  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  void clear() {
    emit(const CartState());
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text('Carrinho', style: AppTypography.displaySmall),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 64, color: AppColors.mutedForeground),
                  const SizedBox(height: 16),
                  Text(
                    'Carrinho vazio',
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione produtos do catálogo',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Items
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _CartItemTile(
                      item: item,
                      formatPrice: _formatPrice,
                      onIncrement: () => context
                          .read<CartCubit>()
                          .increment(item.product.id),
                      onDecrement: () => context
                          .read<CartCubit>()
                          .decrement(item.product.id),
                      onRemove: () => context
                          .read<CartCubit>()
                          .removeItem(item.product.id),
                    );
                  },
                ),
              ),

              // Notes + Total + Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border:
                      Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notes field
                      TextField(
                        onChanged: context.read<CartCubit>().updateNotes,
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Observações...',
                          hintStyle: AppTypography.bodyMedium
                              .copyWith(color: AppColors.mutedForeground),
                          filled: true,
                          fillColor: AppColors.muted,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.mdBorder,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: AppTypography.displaySmall),
                          Text(
                            _formatPrice(state.total),
                            style: AppTypography.displayMedium
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Finalizar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => context.push('/orders/summary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdBorder,
                            ),
                            elevation: 0,
                          ),
                          child: Text('Finalizar Pedido',
                              style: AppTypography.button
                                  .copyWith(fontSize: 16)),
                        ),
                      ),
                    ],
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
// Cart item tile
// ---------------------------------------------------------------------------

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.formatPrice,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final OrderItem item;
  final String Function(double) formatPrice;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPrice(item.product.unitPrice)} / ${item.product.unitOfMeasure}',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${formatPrice(item.subtotal)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Quantity stepper
          Container(
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperButton(
                  icon: Icons.remove,
                  onTap: onDecrement,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onTap: onIncrement,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Remove
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                color: AppColors.destructive, size: 22),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smBorder,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: AppColors.foreground),
      ),
    );
  }
}
