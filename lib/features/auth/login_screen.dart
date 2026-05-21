import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../shared/widgets/dot_grid_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  int _remainingAttempts = 5;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            identifier: _identifierController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          ),
        );
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
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/routes');
          } else if (state is AuthError) {
            setState(() {
              _remainingAttempts = (_remainingAttempts - 1).clamp(0, 5);
              _errorMessage = state.message;
            });
          }
        },
        child: DotGridBackground(
          child: Stack(
            children: [
              // Orb gradients — espelho do AuthShell do web
              Positioned(
                top: -100,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [primaryColor.withValues(alpha: 0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Performaz',
                              style: AppTypography.display(28).copyWith(color: fgColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Painel de Gestão',
                          style: AppTypography.body(16, weight: FontWeight.w500).copyWith(
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: borderColor),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Entre na sua conta',
                                  style: AppTypography.title(22).copyWith(color: fgColor),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use suas credenciais para acessar',
                                  style: AppTypography.body(15).copyWith(color: mutedFg),
                                ),
                                const SizedBox(height: 24),

                                // Error message
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusError.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _errorMessage!,
                                          style: AppTypography.body(12).copyWith(color: AppColors.statusError),
                                        ),
                                        if (_remainingAttempts < 5 && _remainingAttempts > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Tentativas restantes: $_remainingAttempts',
                                              style: AppTypography.body(12, weight: FontWeight.w600)
                                                  .copyWith(color: AppColors.statusError),
                                            ),
                                          ),
                                        if (_remainingAttempts == 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Conta bloqueada. Entre em contato com o gestor.',
                                              style: AppTypography.body(12, weight: FontWeight.w600)
                                                  .copyWith(color: AppColors.statusError),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Identifier field
                                Text(
                                  'E-mail',
                                  style: AppTypography.body(14, weight: FontWeight.w500).copyWith(color: fgColor),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _identifierController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: AppTypography.body(15).copyWith(color: fgColor),
                                  decoration: _inputDecoration(
                                    hintText: 'nome@empresa.com',
                                    prefixIcon: Icons.mail_outline,
                                    isDark: isDark,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe seu e-mail';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Senha',
                                      style: AppTypography.body(14, weight: FontWeight.w500).copyWith(color: fgColor),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/forgot-password'),
                                      child: Text(
                                        'Esqueceu a senha?',
                                        style: AppTypography.body(14, weight: FontWeight.w600)
                                            .copyWith(color: primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  style: AppTypography.body(15).copyWith(color: fgColor),
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _inputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icons.lock_outline,
                                    isDark: isDark,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: mutedFg,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe sua senha';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Remember me
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) =>
                                            setState(() => _rememberMe = v ?? false),
                                        activeColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lembrar de mim por 30 dias',
                                      style: AppTypography.body(14).copyWith(color: mutedFg),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Submit button
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return ElevatedButton(
                                      onPressed:
                                          isLoading || _remainingAttempts == 0 ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: primaryColor,
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Text('Entrar no painel'),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward, size: 18),
                                              ],
                                            ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: borderColor)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OU CONTINUE COM',
                                        style: AppTypography.body(12, weight: FontWeight.w600)
                                            .copyWith(color: mutedFg),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: borderColor)),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Google button
                                OutlinedButton(
                                  onPressed: () {
                                    // Placeholder
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: borderColor),
                                    backgroundColor: cardColor,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'G',
                                            style: AppTypography.body(16, weight: FontWeight.w700)
                                                .copyWith(color: primaryColor),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continuar com Google',
                                        style: AppTypography.body(14).copyWith(color: fgColor),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Footer
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Register placeholder
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Não tem conta? ',
                                        style: AppTypography.body(14).copyWith(color: mutedFg),
                                        children: [
                                          TextSpan(
                                            text: 'Cadastre-se grátis',
                                            style: AppTypography.body(14, weight: FontWeight.w600)
                                                .copyWith(color: primaryColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    final mutedFg = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;
    final fillColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.body(15).copyWith(color: mutedFg.withValues(alpha: 0.6)),
      prefixIcon: Icon(prefixIcon, size: 20, color: mutedFg),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
    );
  }
}
