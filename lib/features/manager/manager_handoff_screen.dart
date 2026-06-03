import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';

class ManagerHandoffScreen extends StatelessWidget {
  const ManagerHandoffScreen({super.key});

  static const webPanelUrl = 'http://localhost:3000/login';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.dashboard_customize_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Painel do gestor',
                    style: AppTypography.title(24).copyWith(color: fgColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O acesso de gestor fica no painel web. Este app mobile esta preparado para a rotina do vendedor em campo.',
                    style: AppTypography.body(14).copyWith(color: mutedFg),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      webPanelUrl,
                      style: AppTypography.mono(13).copyWith(color: fgColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair e entrar como vendedor'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
