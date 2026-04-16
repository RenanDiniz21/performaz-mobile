import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({
    super.key,
    required this.pendingCount,
    this.isSyncing = false,
  });

  final int pendingCount;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && !isSyncing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3), // amber-100
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mediumFg,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mediumFg,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            isSyncing ? 'Sincronizando...' : '$pendingCount pendente(s)',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mediumFg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
