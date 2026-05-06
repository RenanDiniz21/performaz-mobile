import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/dot_grid_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await getIt<ApiClient>().post('/auth/forgot-password', data: {'email': _emailController.text});
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar e-mail')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final fgColor = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: DotGridBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset, color: primaryColor, size: 28),
                  ),
                  const SizedBox(height: 24),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: borderColor),
                    ),
                    child: _emailSent
                        ? _SuccessContent(
                            email: _emailController.text.trim(),
                            fgColor: fgColor,
                            mutedFg: mutedFg,
                            primaryColor: primaryColor,
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Recuperar Senha',
                                  style: AppTypography.title(22).copyWith(color: fgColor),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Informe seu e-mail para receber o link de redefinição.',
                                  style: AppTypography.body(15).copyWith(color: mutedFg),
                                ),
                                const SizedBox(height: 24),

                                // Email field
                                Text(
                                  'E-mail',
                                  style: AppTypography.body(14, weight: FontWeight.w500).copyWith(color: fgColor),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: AppTypography.body(15).copyWith(color: fgColor),
                                  decoration: InputDecoration(
                                    hintText: 'nome@empresa.com',
                                    prefixIcon: Icon(Icons.mail_outline, size: 20, color: mutedFg),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Informe seu e-mail';
                                    }
                                    if (!v.contains('@')) {
                                      return 'E-mail inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Submit
                                ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Enviar Link de Recuperação'),
                                ),
                                const SizedBox(height: 16),

                                // Back to login
                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.pop(),
                                    child: Text(
                                      'Voltar ao login',
                                      style: AppTypography.body(14, weight: FontWeight.w600)
                                          .copyWith(color: primaryColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    required this.email,
    required this.fgColor,
    required this.mutedFg,
    required this.primaryColor,
  });

  final String email;
  final Color fgColor;
  final Color mutedFg;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusSuccess.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'E-mail Enviado',
          style: AppTypography.title(22).copyWith(color: fgColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Um link de recuperação foi enviado para $email.',
          style: AppTypography.body(15).copyWith(color: mutedFg),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Voltar ao login'),
        ),
      ],
    );
  }
}
