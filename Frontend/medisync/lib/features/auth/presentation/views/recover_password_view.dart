import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RecoverPasswordView extends StatefulWidget {
  const RecoverPasswordView({super.key});

  @override
  State<RecoverPasswordView> createState() => _RecoverPasswordViewState();
}

class _RecoverPasswordViewState extends State<RecoverPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    await vm.recoverPassword(_emailCtrl.text.trim());
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
        title: const Text(AppStrings.recoverPassword),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: vm.state.isPasswordRecoverySent
              ? _SuccessState(onBack: () => context.go(AppRoutes.login))
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Recuperá tu contraseña',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresá tu correo electrónico y te enviaremos '
                        'un enlace para restablecer tu contraseña.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 32),
                      AuthTextField(
                        label: AppStrings.email,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(vm),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return AppStrings.requiredField;
                          }
                          if (!_emailRegex.hasMatch(v)) {
                            return AppStrings.invalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: AppStrings.sendRecoveryEmail,
                        isLoading: vm.state.isLoading,
                        icon: Icons.send,
                        onPressed: () => _submit(vm),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  final VoidCallback onBack;

  const _SuccessState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: Color(0xFF4CAF50),
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Correo enviado!',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 12),
        const Text(
          AppStrings.recoveryEmailSent,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: onBack,
          child: const Text('Volver al inicio de sesión'),
        ),
      ],
    );
  }
}
