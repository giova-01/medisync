import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// Post-registration profile completion screen.
/// Full role-specific fields (e.g. Paciente.fechaNacimiento) will be
/// implemented in the user_profile feature.
class ProfileSelectorView extends StatelessWidget {
  const ProfileSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Registro completado!',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu cuenta fue creada correctamente.\n'
                'Podés completar tu perfil en cualquier momento desde la sección Perfil.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(AppStrings.continueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
