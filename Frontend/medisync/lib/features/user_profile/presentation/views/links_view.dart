import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:medisync/features/auth/presentation/widgets/primary_button.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/presentation/viewmodels/links_viewmodel.dart';
import 'package:provider/provider.dart';

class LinksView extends StatefulWidget {
  const LinksView({super.key});

  @override
  State<LinksView> createState() => _LinksViewState();
}

class _LinksViewState extends State<LinksView> {
  final _emailCtrl = TextEditingController();
  TipoVinculo _selectedRol = TipoVinculo.cuidador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LinksViewModel>().loadLinks();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LinksViewModel>();
    final authUser = context.watch<AuthViewModel>().state.user;

    if (vm.state.failure != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.state.failure!.message)),
        );
        vm.clearFailure();
      });
    }

    if (vm.state.requestSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emailCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada correctamente.'),
            backgroundColor: AppColors.success,
          ),
        );
        vm.clearRequestSuccess();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al inicio',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text(AppStrings.links),
      ),
      body: vm.state.isLoading && vm.state.vinculos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadLinks(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (authUser?.tipoPerfil != TipoPerfil.paciente) ...[
                    _RequestSection(
                      emailCtrl: _emailCtrl,
                      selectedRol: _selectedRol,
                      onRolChanged: (r) => setState(() => _selectedRol = r),
                      onSend: () =>
                        vm.requestLink(_emailCtrl.text.trim(), _selectedRol),
                      isLoading: vm.state.isLoading,
                    ),
                    const SizedBox(height: 28),
                  ],
                  _VinculoSection(
                    title: AppStrings.vinculosPendientes,
                    vinculos:
                        vm.state.vinculos.where((v) => v.esPendiente).toList(),
                    authTipoPerfil: authUser?.tipoPerfil,
                    onAccept: (id) => vm.acceptLink(id),
                    onReject: (id) => vm.rejectLink(id),
                    onRevoke: null,
                  ),
                  const SizedBox(height: 20),
                  _VinculoSection(
                    title: AppStrings.vinculosActivos,
                    vinculos:
                        vm.state.vinculos.where((v) => v.esActivo).toList(),
                    authTipoPerfil: authUser?.tipoPerfil,
                    onAccept: null,
                    onReject: null,
                    onRevoke: authUser?.tipoPerfil == TipoPerfil.paciente
                        ? (id) => _confirmRevoke(context, vm, id)
                        : null,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmRevoke(
      BuildContext context, LinksViewModel vm, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.revoke, style: AppTextStyles.heading3),
        content: const Text(AppStrings.confirmRevoke, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: AppTextStyles.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.revoke,
                style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vm.revokeLink(id);
    }
  }
}

class _RequestSection extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TipoVinculo selectedRol;
  final ValueChanged<TipoVinculo> onRolChanged;
  final VoidCallback onSend;
  final bool isLoading;

  const _RequestSection({
    required this.emailCtrl,
    required this.selectedRol,
    required this.onRolChanged,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.requestLink, style: AppTextStyles.heading3),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.body,
          decoration: const InputDecoration(
            hintText: AppStrings.targetEmail,
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<TipoVinculo>(
          segments: TipoVinculo.values
              .map((rol) => ButtonSegment(
                    value: rol,
                    label: Text(rol.label, style: AppTextStyles.body),
                  ))
              .toList(),
          selected: {selectedRol},
          onSelectionChanged: (s) => onRolChanged(s.first),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: AppStrings.requestLink,
          isLoading: isLoading,
          onPressed: emailCtrl.text.isEmpty ? null : onSend,
          icon: Icons.link,
        ),
      ],
    );
  }
}

class _VinculoSection extends StatelessWidget {
  final String title;
  final List<Vinculo> vinculos;
  final TipoPerfil? authTipoPerfil;
  final void Function(int)? onAccept;
  final void Function(int)? onReject;
  final void Function(int)? onRevoke;

  const _VinculoSection({
    required this.title,
    required this.vinculos,
    required this.authTipoPerfil,
    required this.onAccept,
    required this.onReject,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (vinculos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin resultados.', style: AppTextStyles.bodySecondary),
          )
        else
          ...vinculos.map((v) => _VinculoCard(
                vinculo: v,
                authTipoPerfil: authTipoPerfil,
                onAccept: onAccept,
                onReject: onReject,
                onRevoke: onRevoke,
              )),
      ],
    );
  }
}

class _VinculoCard extends StatelessWidget {
  final Vinculo vinculo;
  final TipoPerfil? authTipoPerfil;
  final void Function(int)? onAccept;
  final void Function(int)? onReject;
  final void Function(int)? onRevoke;

  const _VinculoCard({
    required this.vinculo,
    required this.authTipoPerfil,
    required this.onAccept,
    required this.onReject,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final u = vinculo.usuarioVinculado;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.nombreCompleto, style: AppTextStyles.body),
                      Text(u.email, style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
                _EstadoBadge(vinculo.estado),
              ],
            ),
            const SizedBox(height: 4),
            Text(vinculo.tipoVinculo.label, style: AppTextStyles.caption),
            if (onAccept != null || onReject != null || onRevoke != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onAccept != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text(AppStrings.accept),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success),
                        onPressed: () => onAccept!(vinculo.id),
                      ),
                    ),
                  if (onAccept != null && onReject != null)
                    const SizedBox(width: 8),
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text(AppStrings.reject),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error),
                        onPressed: () => onReject!(vinculo.id),
                      ),
                    ),
                  if (onRevoke != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.link_off, size: 20),
                        label: const Text(AppStrings.revoke),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error),
                        onPressed: () => onRevoke!(vinculo.id),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoVinculo estado;

  const _EstadoBadge(this.estado);

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      EstadoVinculo.aceptado => AppColors.success,
      EstadoVinculo.pendiente => AppColors.warning,
      EstadoVinculo.rechazado || EstadoVinculo.revocado => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(estado.label,
          style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}
