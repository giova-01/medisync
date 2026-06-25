import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:medisync/features/auth/presentation/widgets/primary_button.dart';
import 'package:medisync/features/user_profile/domain/entities/cuidador.dart';
import 'package:medisync/features/user_profile/domain/entities/paciente.dart';
import 'package:medisync/features/user_profile/domain/entities/profesional_salud.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';
import 'package:medisync/features/user_profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _patologiasCtrl = TextEditingController();
  final _parentescoCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfile();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _fechaCtrl.dispose();
    _patologiasCtrl.dispose();
    _parentescoCtrl.dispose();
    _matriculaCtrl.dispose();
    _especialidadCtrl.dispose();
    super.dispose();
  }

  void _initControllers(Usuario user) {
    _nombreCtrl.text = user.nombre;
    _apellidoCtrl.text = user.apellido;
    if (user is Paciente) {
      _fechaCtrl.text =
          user.fechaNacimiento?.toIso8601String().split('T').first ?? '';
      _patologiasCtrl.text = user.patologias.join(', ');
    } else if (user is Cuidador) {
      _parentescoCtrl.text = user.parentesco ?? '';
    } else if (user is ProfesionalSalud) {
      _matriculaCtrl.text = user.matricula ?? '';
      _especialidadCtrl.text = user.especialidad ?? '';
    }
  }

  Future<void> _save(ProfileViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = vm.state.user;
    if (user == null) return;

    DateTime? fechaNac;
    if (_fechaCtrl.text.isNotEmpty) {
      fechaNac = DateTime.tryParse(_fechaCtrl.text);
    }

    await vm.updateProfile(UpdateProfileParams(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      fechaNacimiento: fechaNac,
      patologias: user is Paciente
          ? _patologiasCtrl.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : null,
      parentesco:
          user is Cuidador ? _parentescoCtrl.text.trim() : null,
      matricula: user is ProfesionalSalud
          ? _matriculaCtrl.text.trim()
          : null,
      especialidad: user is ProfesionalSalud
          ? _especialidadCtrl.text.trim()
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = vm.state.user;

    if (user != null && !_initialized) {
      _initialized = true;
      _initControllers(user);
    }

    if (vm.state.failure != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.state.failure!.message)),
        );
        vm.clearFailure();
      });
    }

    if (vm.state.updateSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente.'),
            backgroundColor: AppColors.success,
          ),
        );
        vm.clearSuccess();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al inicio',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text(AppStrings.profile),
      ),
      body: vm.state.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Expanded(child: _buildForm(vm, user)),
                    _ActionsFooter(
                      isLoading: vm.state.isLoading,
                      onSave: () => _save(vm),
                      onLogout: () => _confirmLogout(context),
                    ),
                  ],
                ),
    );
  }

  Widget _buildForm(ProfileViewModel vm, Usuario user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 28),
            _SectionLabel(AppStrings.nombre),
            const SizedBox(height: 8),
            _Field(
              controller: _nombreCtrl,
              hint: AppStrings.nombre,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? AppStrings.nameTooShort : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel(AppStrings.apellido),
            const SizedBox(height: 8),
            _Field(
              controller: _apellidoCtrl,
              hint: AppStrings.apellido,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? AppStrings.nameTooShort : null,
            ),
            const SizedBox(height: 20),
            if (user is Paciente) ..._pacienteFields(),
            if (user is Cuidador) ..._cuidadorFields(),
            if (user is ProfesionalSalud) ..._profesionalFields(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(AppStrings.logout,
                  style: AppTextStyles.heading3, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(AppStrings.confirmLogoutMessage,
                  style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white),
                  child: const Text(AppStrings.logout,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(AppStrings.cancel, style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthViewModel>().logout();
    }
  }

  List<Widget> _pacienteFields() => [
        _SectionLabel(AppStrings.fechaNacimiento),
        const SizedBox(height: 8),
        _Field(
          controller: _fechaCtrl,
          hint: 'AAAA-MM-DD',
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 20),
        _SectionLabel(AppStrings.patologias),
        const SizedBox(height: 8),
        _Field(
          controller: _patologiasCtrl,
          hint: AppStrings.patologias,
          maxLines: 3,
        ),
      ];

  List<Widget> _cuidadorFields() => [
        _SectionLabel(AppStrings.parentesco),
        const SizedBox(height: 8),
        _Field(
          controller: _parentescoCtrl,
          hint: AppStrings.parentesco,
        ),
      ];

  List<Widget> _profesionalFields() => [
        _SectionLabel(AppStrings.matricula),
        const SizedBox(height: 8),
        _Field(
          controller: _matriculaCtrl,
          hint: AppStrings.matricula,
        ),
        const SizedBox(height: 20),
        _SectionLabel(AppStrings.especialidad),
        const SizedBox(height: 8),
        _Field(
          controller: _especialidadCtrl,
          hint: AppStrings.especialidad,
        ),
      ];
}

class _ActionsFooter extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onLogout;

  const _ActionsFooter({
    required this.isLoading,
    required this.onSave,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: AppStrings.saveChanges,
                isLoading: isLoading,
                onPressed: onSave,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(AppStrings.logout,
                      style: TextStyle(color: AppColors.error, fontSize: 18)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Usuario user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.person, size: 40, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.nombreCompleto, style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(user.email, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(user.tipoPerfil.label,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.label.copyWith(color: AppColors.onSurface));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.body,
      decoration: InputDecoration(hintText: hint),
      validator: validator,
    );
  }
}
