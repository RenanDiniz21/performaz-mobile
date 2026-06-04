import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';
import 'route_cubit.dart';

enum SkipReason {
  foraRota('Fora da rota hoje', 'fora_da_rota'),
  semTempo('Sem tempo', 'sem_tempo'),
  clienteFechou('Cliente fechou', 'cliente_fechou');

  const SkipReason(this.label, this.value);
  final String label;
  final String value;
}

String _skipReasonLabel(String value) {
  return switch (value) {
    'fora_da_rota' => 'Fora da rota',
    'sem_tempo' => 'Sem tempo',
    'cliente_fechou' => 'Cliente fechou',
    _ => value,
  };
}

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({
    super.key,
    required this.stop,
  });

  final RouteStop stop;

  void _showSkipSheet(BuildContext context, RouteStop stop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    showModalBottomSheet<SkipReason>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pular Visita',
                  style: AppTypography.title(20).copyWith(color: fgColor)),
              const SizedBox(height: 4),
              Text(stop.clientName,
                  style: AppTypography.body(14).copyWith(color: mutedFg)),
              const SizedBox(height: 20),
              Text('Por que você não vai visitar?',
                  style: AppTypography.body(14, weight: FontWeight.w500)
                      .copyWith(color: fgColor)),
              const SizedBox(height: 12),
              ...SkipReason.values.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(reason);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: fgColor,
                          side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(reason.label,
                            style: AppTypography.body(14,
                                weight: FontWeight.w500)),
                      ),
                    ),
                  )),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text('Cancelar',
                      style: AppTypography.body(14).copyWith(color: mutedFg)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((reason) {
      if (reason != null && context.mounted) {
        context.read<RouteCubit>().markClientSkipped(
              stop.clientId,
              reason.value,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stop.clientName} — visita pulada'),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(stop.clientName, style: AppTypography.title(20)),
      ),
      body: DotGridBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client header
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          stop.clientName[0].toUpperCase(),
                          style: AppTypography.title(18).copyWith(color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stop.clientName,
                                style: AppTypography.title(18).copyWith(color: fgColor)),
                            Text(stop.address,
                                style: AppTypography.body(13).copyWith(color: mutedFg)),
                            if (stop.segment != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(stop.segment!,
                                    style: AppTypography.body(11, weight: FontWeight.w500)
                                        .copyWith(color: primaryColor)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Navigate to client
                  if (stop.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.directions_outlined, size: 18,
                            color: primaryColor),
                        label: Text('Como chegar',
                            style: AppTypography.body(13, weight: FontWeight.w600)
                                .copyWith(color: primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () {
                          if (stop.checkinLatitude != null && stop.checkinLongitude != null) {
                            context.push('/routes/${stop.clientId}/navigate', extra: stop);
                          } else {
                            _launchMaps(stop.address);
                          }
                        },
                      ),
                    ),
                  ],
                  // Phone — tap to call
                  if (stop.phone != null && stop.phone!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _launchPhone(stop.phone!),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(stop.phone!,
                                style: AppTypography.body(14, weight: FontWeight.w500)
                                    .copyWith(color: primaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Order history + last visit
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Histórico',
                      style: AppTypography.body(13, weight: FontWeight.w600)
                          .copyWith(color: fgColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Pedidos',
                          value: '${stop.totalOrders ?? 0}',
                          icon: Icons.receipt_long_outlined,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'Faturamento',
                          value: _formatCurrency(stop.totalRevenue ?? 0),
                          icon: Icons.trending_up,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    Icons.calendar_today,
                    'Último pedido',
                    stop.lastOrderDate != null
                        ? _formatDate(stop.lastOrderDate!)
                        : '–',
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    Icons.location_on_outlined,
                    'Última visita',
                    stop.checkinAt != null
                        ? _formatDate(stop.checkinAt!)
                        : '–',
                  ),
                ],
              ),
            ),

            // Notes from manager
            if (stop.clientNotes != null && stop.clientNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_outlined, size: 16, color: mutedFg),
                        const SizedBox(width: 6),
                        Text('Observações',
                            style: AppTypography.body(13, weight: FontWeight.w600)
                                .copyWith(color: fgColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(stop.clientNotes!,
                        style: AppTypography.body(13).copyWith(color: mutedFg)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Skipped status
            if (stop.status == VisitStatus.pulado) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inactiveGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.skip_next,
                        color: AppColors.inactiveGray, size: 20),
                    const SizedBox(width: 8),
                    Text('Visita pulada',
                        style: AppTypography.body(14, weight: FontWeight.w600)
                            .copyWith(color: AppColors.inactiveGray)),
                    if (stop.noSaleReason != null) ...[
                      const SizedBox(width: 8),
                      Text('— ${_skipReasonLabel(stop.noSaleReason!)}',
                          style: AppTypography.body(13)
                              .copyWith(color: AppColors.inactiveGray)),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Check-in (recommended, not mandatory)
              if (stop.status == VisitStatus.pendente) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.my_location, size: 18, color: primaryColor),
                    label: Text('Fazer Check-in',
                        style: AppTypography.body(14, weight: FontWeight.w600)
                            .copyWith(color: primaryColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () => context.push(
                        '/routes/${stop.clientId}/checkin',
                        extra: stop),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Main actions — always available
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined,
                            size: 18),
                        label: Text('Fazer Pedido',
                            style: AppTypography.body(14,
                                weight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            context.push('/orders/catalog', extra: {
                          'clientId': stop.clientId,
                          'clientName': stop.clientName,
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.cancel_outlined,
                            size: 18, color: AppColors.statusWarning),
                        label: Text('Sem Venda',
                            style: AppTypography.body(14,
                                    weight: FontWeight.w600)
                                .copyWith(
                                    color: AppColors.statusWarning)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.statusWarning
                                  .withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () =>
                            context.push('/orders/no-sale', extra: {
                          'clientId': stop.clientId,
                          'clientName': stop.clientName,
                          'routeId': stop.routeId,
                        }),
                      ),
                    ),
                  ),
                ],
              ),

              // Skip — only for pending stops
              if (stop.status == VisitStatus.pendente) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.skip_next_outlined,
                        size: 18, color: AppColors.inactiveGray),
                    label: Text('Pular Visita',
                        style: AppTypography.body(13)
                            .copyWith(color: AppColors.inactiveGray)),
                    onPressed: () => _showSkipSheet(context, stop),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _launchPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
  if (await launcher.canLaunchUrl(uri)) {
    await launcher.launchUrl(uri);
  }
}

Future<void> _launchMaps(String address, {double? lat, double? lng}) async {
  Uri uri;
  if (lat != null && lng != null) {
    uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(address)})');
  } else {
    uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(address)}');
  }

  if (await launcher.canLaunchUrl(uri)) {
    await launcher.launchUrl(uri);
  } else {
    final webUri = Uri.parse(
        'https://www.openstreetmap.org/search?query=${Uri.encodeComponent(address)}');
    await launcher.launchUrl(webUri, mode: launcher.LaunchMode.externalApplication);
  }
}

String _formatCurrency(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  return '$d/$m/$y';
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTypography.body(11, weight: FontWeight.w500)
                      .copyWith(color: mutedFg)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.metric(18).copyWith(color: fgColor)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;

    return Row(
      children: [
        Icon(icon, size: 16, color: mutedFg),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTypography.body(13).copyWith(color: mutedFg)),
        Expanded(child: Text(value, style: AppTypography.body(13).copyWith(color: fgColor))),
      ],
    );
  }
}
