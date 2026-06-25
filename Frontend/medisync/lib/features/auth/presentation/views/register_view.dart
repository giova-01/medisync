import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/domain/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  TipoPerfil? _selectedPerfil;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  // Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special
  static final _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (_selectedPerfil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.mustSelectProfile)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    await vm.register(
      RegisterParams(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        tipoPerfil: _selectedPerfil!,
      ),
    );
    // GoRouter redirect handles navigation on success.
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.state.failure != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(vm.state.failure!.message)),
          );
        vm.clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.register),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile selector
                Text(
                  AppStrings.selectProfile,
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.selectProfileSubtitle,
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 16),
                _ProfileSelector(
                  selected: _selectedPerfil,
                  onChanged: (v) => setState(() => _selectedPerfil = v),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),

                // Personal data
                Text('Datos personales', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                AuthTextField(
                  label: AppStrings.nombre,
                  controller: _nombreCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? AppStrings.nameTooShort
                      : null,
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  label: AppStrings.apellido,
                  controller: _apellidoCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? AppStrings.nameTooShort
                      : null,
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  label: AppStrings.email,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.requiredField;
                    if (!_emailRegex.hasMatch(v)) return AppStrings.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  label: AppStrings.password,
                  controller: _passwordCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.requiredField;
                    if (v.length < 8) return AppStrings.passwordTooShort;
                    if (!_passwordRegex.hasMatch(v)) {
                      return AppStrings.passwordRequirements;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  label: AppStrings.confirmPassword,
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(vm),
                  validator: (v) => v != _passwordCtrl.text
                      ? AppStrings.passwordsDontMatch
                      : null,
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: AppStrings.register,
                  isLoading: vm.state.isLoading,
                  icon: Icons.person_add,
                  onPressed: () => _submit(vm),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.hasAccount, style: AppTextStyles.body),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        AppStrings.login,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile selection cards
// ---------------------------------------------------------------------------

class _ProfileSelector extends StatelessWidget {
  final TipoPerfil? selected;
  final ValueChanged<TipoPerfil> onChanged;

  const _ProfileSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: TipoPerfil.values
          .map((p) => _ProfileCard(
                perfil: p,
                isSelected: selected == p,
                onTap: () => onChanged(p),
              ))
          .toList(),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final TipoPerfil perfil;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.perfil,
    required this.isSelected,
    required this.onTap,
  });

  static const _icons = {
    TipoPerfil.paciente: Icons.person,
    TipoPerfil.cuidador: Icons.favorite,
    TipoPerfil.profesionalSalud: Icons.local_hospital,
  };

  static const _descriptions = {
    TipoPerfil.paciente: AppStrings.profilePacienteDesc,
    TipoPerfil.cuidador: AppStrings.profileCuidadorDesc,
    TipoPerfil.profesionalSalud: AppStrings.profileProfesionalDesc,
  };

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_icons[perfil], color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perfil.label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _descriptions[perfil]!,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
