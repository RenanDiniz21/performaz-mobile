import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dot_grid_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final fgColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state.user;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(title: Text('Perfil', style: AppTypography.title(20))),
          body: DotGridBackground(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + name
                AppCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryColor,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: AppTypography.display(
                            28,
                          ).copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: AppTypography.title(20).copyWith(color: fgColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: AppTypography.body(14).copyWith(color: mutedFg),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          user.role.name,
                          style: AppTypography.body(
                            12,
                            weight: FontWeight.w600,
                          ).copyWith(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info rows
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Telefone',
                        value: user.phone ?? '–',
                      ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'ID',
                        value: user.id,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(context, user),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar Perfil'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context),
                    icon: const Icon(Icons.lock_reset, size: 18),
                    label: const Text('Alterar senha'),
                  ),
                ),
                const SizedBox(height: 12),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair da Conta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      side: BorderSide(
                        color: AppColors.destructive.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, User user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu telefone';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                context.read<AuthBloc>().add(
                  AuthProfileUpdateRequested(
                    name: nameController.text,
                    phone: phoneController.text,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Salvar perfil'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
    });
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alterar senha'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(labelText: 'Senha atual'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe sua senha atual';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'A nova senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                context.read<AuthBloc>().add(
                  AuthPasswordChangeRequested(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Salvar senha'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      currentPasswordController.dispose();
      newPasswordController.dispose();
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final fgColor = isDark
        ? AppColors.foregroundDark
        : AppColors.foregroundLight;

    return Row(
      children: [
        Icon(icon, size: 20, color: mutedFg),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.body(
                12,
                weight: FontWeight.w500,
              ).copyWith(color: mutedFg),
            ),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.body(14).copyWith(color: fgColor)),
          ],
        ),
      ],
    );
  }
}
