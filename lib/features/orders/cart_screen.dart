import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/storage/local_database.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/models/order.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/app_card.dart';
import '../routes/route_cubit.dart';
import 'order_submission.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CartState extends Equatable {
  const CartState({
    this.clientId,
    this.clientName,
    this.items = const [],
    this.notes = '',
  });

  final String? clientId;
  final String? clientName;
  final List<OrderItem> items;
  final String notes;

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    String? clientId,
    String? clientName,
    List<OrderItem>? items,
    String? notes,
    bool clearClient = false,
  }) {
    return CartState(
      clientId: clearClient ? null : (clientId ?? this.clientId),
      clientName: clearClient ? null : (clientName ?? this.clientName),
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [clientId, clientName, items, notes];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void initCart({required String clientId, required String clientName}) {
    if (state.clientId != clientId) {
      emit(CartState(clientId: clientId, clientName: clientName));
    } else if (state.clientName != clientName) {
      emit(state.copyWith(clientName: clientName));
    }
  }

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

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _submitting = false;

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _onConfirm(BuildContext context) async {
    final cartState = context.read<CartCubit>().state;
    if (cartState.clientId == null || cartState.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final sellerId = authState.user.id;

    setState(() => _submitting = true);

    final itemsJson = jsonEncode(
      cartState.items
          .map((i) => {
                'productId': i.product.id,
                'quantity': i.quantity,
                'unitPrice': i.product.unitPrice,
              })
          .toList(),
    );

    late final OrderSubmissionResult result;
    try {
      result = await submitOrderOnlineFirst(
        createRemoteOrder: () async {
          await getIt<OrderRepository>().createOrder(
            vendorId: sellerId,
            clientId: cartState.clientId!,
            items: cartState.items,
            notes: cartState.notes,
          );
        },
        savePendingOrder: () async {
          final orderId = DateTime.now().toIso8601String();
          await getIt<LocalDatabase>().insertOrder(
            PendingOrdersCompanion.insert(
              id: orderId,
              clientId: cartState.clientId!,
              sellerId: sellerId,
              itemsJson: itemsJson,
              notes: drift.Value(
                cartState.notes.isNotEmpty ? cartState.notes : null,
              ),
              createdAt: DateTime.now(),
            ),
          );
        },
      );

      if (result == OrderSubmissionResult.pendingSync) {
        getIt<SyncService>().syncAll();
      }
      if (!context.mounted) return;
      context.read<RouteCubit>().markClientSale(cartState.clientId!);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar pedido')),
      );
      return;
    }

    if (!context.mounted) return;
    setState(() => _submitting = false);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final cartCubit = context.read<CartCubit>();
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.statusSuccess, size: 28),
            const SizedBox(width: 12),
            Text('Pedido Confirmado', style: AppTypography.title(20)),
          ],
        ),
        content: Text(
          result == OrderSubmissionResult.synced
              ? 'Pedido enviado com sucesso!'
              : 'Pedido salvo para sincronização!',
          style: AppTypography.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cartCubit.clear();
              Navigator.of(dialogContext).pop();
              router.go('/routes');
            },
            child: Text(
              'OK',
              style: AppTypography.body(14).copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Carrinho', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: mutedFg.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Carrinho vazio',
                      style: AppTypography.body(16).copyWith(color: mutedFg)),
                  const SizedBox(height: 8),
                  Text('Adicione produtos do catálogo',
                      style: AppTypography.body(13).copyWith(color: mutedFg)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Client header
                    if (state.clientName != null)
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                state.clientName![0].toUpperCase(),
                                style: AppTypography.title(14)
                                    .copyWith(color: primaryColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cliente',
                                      style: AppTypography.body(11,
                                              weight: FontWeight.w500)
                                          .copyWith(color: mutedFg)),
                                  Text(state.clientName!,
                                      style: AppTypography.title(15)
                                          .copyWith(color: fgColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Items header
                    Row(
                      children: [
                        Text(
                          'Itens (${state.items.length})',
                          style:
                              AppTypography.body(13, weight: FontWeight.w600)
                                  .copyWith(color: mutedFg),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.pop(),
                          icon: Icon(Icons.add, size: 16, color: primaryColor),
                          label: Text('Adicionar',
                              style: AppTypography.body(13,
                                      weight: FontWeight.w600)
                                  .copyWith(color: primaryColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Item list
                    ...state.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CartItemTile(
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
                          ),
                        )),

                    const SizedBox(height: 8),

                    // Notes field
                    TextField(
                      onChanged: context.read<CartCubit>().updateNotes,
                      style: AppTypography.body(14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Observações...',
                        hintStyle: AppTypography.body(14).copyWith(
                            color: mutedFg),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Total + Confirm
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: AppTypography.title(18)
                                    .copyWith(color: fgColor)),
                            Text(_formatPrice(state.total),
                                style: AppTypography.metric(24)
                                    .copyWith(color: primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _submitting ? null : () => _onConfirm(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primaryColor.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text('Confirmar Pedido',
                                  style: AppTypography.body(16,
                                      weight: FontWeight.w600)),
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
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTypography.body(14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPrice(item.product.unitPrice)} / ${item.product.unitOfMeasure}',
                  style: AppTypography.body(12, weight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${formatPrice(item.subtotal)}',
                  style: AppTypography.body(13, weight: FontWeight.w600)
                      .copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),

          // Quantity stepper
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                    style: AppTypography.body(14, weight: FontWeight.w700),
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
