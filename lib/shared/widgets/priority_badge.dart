import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

enum Priority { high, medium, low }

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (priority) {
      Priority.high => (AppColors.highBg, AppColors.highFg, 'Alta'),
      Priority.medium => (AppColors.mediumBg, AppColors.mediumFg, 'Média'),
      Priority.low => (AppColors.lowBg, AppColors.lowFg, 'Baixa'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smBorder,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
