import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/auth/auth_repository.dart';
import '../../shared/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String? _profileMessage;
  String? _passwordMessage;
  bool _profileSuccess = false;
  bool _passwordSuccess = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _nameController.text = state.user.name;
      _phoneController.text = state.user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _profileMessage = null;
    });

    try {
      await context.read<AuthRepository>().updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      setState(() {
        _profileMessage = 'Perfil atualizado com sucesso!';
        _profileSuccess = true;
      });
      // Refresh auth state
      context.read<AuthBloc>().add(const AuthCheckRequested());
    } catch (e) {
      setState(() {
        _profileMessage = 'Erro ao salvar perfil. Tente novamente.';
        _profileSuccess = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordMessage = 'As senhas não coincidem.';
        _passwordSuccess = false;
      });
      return;
    }

    if (_newPasswordController.text.length < 8) {
      setState(() {
        _passwordMessage = 'A nova senha deve ter no mínimo 8 caracteres.';
        _passwordSuccess = false;
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordMessage = null;
    });

    try {
      await context.read<AuthRepository>().changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      setState(() {
        _passwordMessage = 'Senha alterada com sucesso!';
        _passwordSuccess = true;
      });
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      setState(() {
        _passwordMessage = 'Senha atual incorreta ou erro no servidor.';
        _passwordSuccess = false;
      });
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => context.pop(),
        ),
        title: Text('Perfil', style: AppTypography.displaySmall),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAvatar(user),
                const SizedBox(height: 24),
                _buildProfileCard(),
                const SizedBox(height: 16),
                _buildPasswordCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.muted,
            backgroundImage: _pickedImage != null
                ? null // Would use FileImage in production
                : (user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null),
            child: _pickedImage == null && user?.photoUrl == null
                ? Icon(Icons.person, size: 48, color: AppColors.mutedForeground)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.xlBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dados pessoais', style: AppTypography.displaySmall),
          const SizedBox(height: 16),

          if (_profileMessage != null) ...[
            _buildMessage(_profileMessage!, _profileSuccess),
            const SizedBox(height: 12),
          ],

          // Name
          Text('Nome', style: AppTypography.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(
              hintText: 'Seu nome completo',
              prefixIcon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),

          // Phone
          Text('Telefone', style: AppTypography.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(
              hintText: '(11) 99999-9999',
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 24),

          // Save
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdBorder,
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Salvar', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.xlBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alterar Senha', style: AppTypography.displaySmall),
          const SizedBox(height: 16),

          if (_passwordMessage != null) ...[
            _buildMessage(_passwordMessage!, _passwordSuccess),
            const SizedBox(height: 12),
          ],

          // Current password
          Text('Senha atual', style: AppTypography.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrent,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.mutedForeground,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // New password
          Text('Nova senha', style: AppTypography.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(
              hintText: 'Mínimo 8 caracteres',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.mutedForeground,
                ),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm password
          Text('Confirmar nova senha', style: AppTypography.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: AppTypography.bodyMedium,
            decoration: _inputDecoration(
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
            ),
          ),
          const SizedBox(height: 24),

          // Change password button
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdBorder,
                ),
              ),
              child: _isChangingPassword
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Alterar Senha',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.successBg : AppColors.highBg,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: isSuccess ? AppColors.success : AppColors.highFg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isSuccess ? AppColors.success : AppColors.highFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.mutedForeground.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.mutedForeground),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdBorder,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorder,
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorder,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorder,
        borderSide: BorderSide(color: AppColors.destructive, width: 1),
      ),
    );
  }
}
