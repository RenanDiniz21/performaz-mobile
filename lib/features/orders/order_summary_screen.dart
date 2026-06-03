import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dart:convert';
import 'package:drift/drift.dart' as drift;

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/storage/local_database.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/widgets/app_card.dart';
import '../routes/route_cubit.dart';
import 'cart_screen.dart';
import 'order_submission.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _onConfirm(BuildContext context) async {
    final cartState = context.read<CartCubit>().state;
    if (cartState.clientId == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final sellerId = authState.user.id;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar pedido')));
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 28),
            const SizedBox(width: 12),
            Text('Pedido Confirmado', style: AppTypography.title(20)),
          ],
        ),
        content: Text(
          result == OrderSubmissionResult.synced
              ? 'Pedido enviado com sucesso. Pontos e metas atualizados!'
              : 'Pedido registrado e pronto para sincronização!',
          style: AppTypography.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<CartCubit>().clear();
              Navigator.of(context).pop();
              context.go('/routes');
            },
            child: Text(
              'OK',
              style: AppTypography.body(14).copyWith(
                color: Theme.of(context).colorScheme.primary,
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
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Resumo do Pedido', style: AppTypography.title(20)),
        centerTitle: false,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Client header
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente',
                              style: AppTypography.body(12, weight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(state.clientName ?? '–',
                              style: AppTypography.title(20)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items header
                    Text('Itens',
                        style: AppTypography.body(12, weight: FontWeight.w500)
                            .copyWith(fontSize: 14)),
                    const SizedBox(height: 8),

                    // Item list
                    ...state.items.map((item) => AppCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: AppTypography.body(14).copyWith(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.quantity}x ${_formatPrice(item.product.unitPrice)}',
                                      style: AppTypography.body(12, weight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatPrice(item.subtotal),
                                style: AppTypography.body(14).copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 8),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: AppTypography.title(20)),
                          Text(
                            _formatPrice(state.total),
                            style: AppTypography.metric(24)
                                .copyWith(color: primaryColor),
                          ),
                        ],
                      ),
                    ),

                    // Notes
                    if (state.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Observações',
                                style: AppTypography.body(12, weight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(state.notes,
                                style: AppTypography.body(14)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.foreground,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                              ),
                            ),
                            child: Text('Voltar',
                                style: AppTypography.body(14)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _onConfirm(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Confirmar',
                                style: AppTypography.body(15, weight: FontWeight.w600)),
                          ),
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
