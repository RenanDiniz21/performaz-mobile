import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../shared/models/route.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({
    super.key,
    required this.stop,
  });

  final RouteStop stop;

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
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Last visit info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Última Visita',
                      style: AppTypography.body(14, weight: FontWeight.w600).copyWith(color: fgColor)),
                  const SizedBox(height: 8),
                  _InfoRow(Icons.calendar_today, 'Data', stop.checkinAt?.toIso8601String().split('T').first ?? '–'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => context.push('/routes/${stop.clientId}/checkin', extra: stop),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: const Text('Pedido'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => context.push('/orders/catalog', extra: {
                      'clientId': stop.clientId,
                      'clientName': stop.clientName,
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.cancel_outlined, size: 18, color: AppColors.statusWarning),
                label: Text(
                  'Sem Venda',
                  style: AppTypography.body(15).copyWith(color: AppColors.statusWarning),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.statusWarning.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => context.push('/orders/no-sale', extra: {
                  'clientId': stop.clientId,
                  'clientName': stop.clientName,
                }),
              ),
            ),
          ],
        ),
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
