import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/client.dart';
import '../../shared/models/order.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientDetailState {
  const ClientDetailState({
    this.client,
    this.recentOrders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final Client? client;
  final List<Order> recentOrders;
  final bool isLoading;
  final String? errorMessage;

  ClientDetailState copyWith({
    Client? client,
    List<Order>? recentOrders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClientDetailState(
      client: client ?? this.client,
      recentOrders: recentOrders ?? this.recentOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class ClientDetailCubit extends Cubit<ClientDetailState> {
  ClientDetailCubit({required this.clientId})
      : super(const ClientDetailState());

  final String clientId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // TODO: fetch from repository
      await Future<void>.delayed(const Duration(milliseconds: 400));

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar cliente: $e',
      ));
    }
  }

  Future<void> registerNoSaleVisit(String reason) async {
    // TODO: persist visit-without-sale
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientDetailCubit(clientId: clientId)..load(),
      child: const _ClientDetailView(),
    );
  }
}

class _ClientDetailView extends StatelessWidget {
  const _ClientDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text('Detalhes do Cliente', style: AppTypography.displaySmall),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocBuilder<ClientDetailCubit, ClientDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
              child:
                  Text(state.errorMessage!, style: AppTypography.bodyMedium),
            );
          }

          final client = state.client;
          if (client == null) {
            return Center(
              child: Text(
                'Cliente não encontrado',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.mutedForeground),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ClientInfoCard(client: client),
              const SizedBox(height: 16),
              _RecentOrdersSection(orders: state.recentOrders),
              const SizedBox(height: 24),
              _ActionButtons(clientId: client.id),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client info card
// ---------------------------------------------------------------------------

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name, style: AppTypography.displayMedium),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.badge_outlined, label: 'CNPJ', value: client.cnpj),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Endereço', value: client.address),
          if (client.phone != null) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: client.phone!),
          ],
          if (client.email != null) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, label: 'E-mail', value: client.email!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.label),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent orders
// ---------------------------------------------------------------------------

class _RecentOrdersSection extends StatelessWidget {
  const _RecentOrdersSection({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimos Pedidos', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Nenhum pedido recente',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...orders.take(3).map((order) => _OrderExpandableCard(order: order)),
      ],
    );
  }
}

class _OrderExpandableCard extends StatelessWidget {
  const _OrderExpandableCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(order.createdAt);
    final totalStr = 'R\$ ${order.total.toStringAsFixed(2)}';

    final (statusLabel, statusColor) = switch (order.status) {
      OrderStatus.pending => ('Pendente', AppColors.mutedForeground),
      OrderStatus.confirmed => ('Confirmado', AppColors.lowFg),
      OrderStatus.delivered => ('Entregue', AppColors.success),
      OrderStatus.cancelled => ('Cancelado', AppColors.destructive),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pedido $dateStr',
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  statusLabel,
                  style: AppTypography.bodySmall.copyWith(color: statusColor),
                ),
              ],
            ),
            subtitle: Text(totalStr, style: AppTypography.label),
            children: [
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.product.name}',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      Text(
                        'R\$ ${item.subtotal.toStringAsFixed(2)}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
              elevation: 0,
            ),
            onPressed: () => context.push('/orders/new?clientId=$clientId'),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text('Iniciar Pedido', style: AppTypography.button),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foreground,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
            ),
            onPressed: () => _showNoSaleDialog(context),
            icon: const Icon(Icons.cancel_outlined, size: 20),
            label: Text(
              'Registrar Visita sem Venda',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showNoSaleDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Text('Motivo da visita sem venda',
              style: AppTypography.displaySmall),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Descreva o motivo...',
              hintStyle:
                  AppTypography.bodyMedium.copyWith(color: AppColors.mutedForeground),
              border: OutlineInputBorder(borderRadius: AppRadius.mdBorder),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdBorder,
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.mutedForeground)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                elevation: 0,
              ),
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isNotEmpty) {
                  context
                      .read<ClientDetailCubit>()
                      .registerNoSaleVisit(reason);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visita registrada')),
                  );
                }
              },
              child: Text('Confirmar', style: AppTypography.button),
            ),
          ],
        );
      },
    );
  }
}
