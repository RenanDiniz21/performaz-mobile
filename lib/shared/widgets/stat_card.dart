import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.trendPositive = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.body(12, weight: FontWeight.w500)),
              if (icon != null)
                Icon(icon, size: 18, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.metric(28).copyWith(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text(
              trend!,
              style: AppTypography.body(12, weight: FontWeight.w500).copyWith(
                color: trendPositive ? AppColors.statusSuccess : AppColors.statusError,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
