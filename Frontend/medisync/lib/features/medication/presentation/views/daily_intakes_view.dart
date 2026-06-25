import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';
import 'package:medisync/features/medication/presentation/viewmodels/intakes_viewmodel.dart';
import 'package:provider/provider.dart';

class DailyIntakesView extends StatefulWidget {
  const DailyIntakesView({super.key});

  @override
  State<DailyIntakesView> createState() => _DailyIntakesViewState();
}

class _DailyIntakesViewState extends State<DailyIntakesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IntakesViewModel>().loadIntakes(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IntakesViewModel>();

    if (vm.state.failure != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.state.failure!.message)),
        );
        vm.clearFailure();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dailyIntakes)),
      body: vm.state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.state.tomas.isEmpty
              ? _emptyState()
              : _tomasList(vm),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication_outlined,
                size: 72, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text(AppStrings.noIntakesToday, style: AppTextStyles.bodySecondary),
          ],
        ),
      );

  Widget _tomasList(IntakesViewModel vm) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.state.tomas.length,
        itemBuilder: (_, i) => _TomaCard(
          toma: vm.state.tomas[i],
          onConfirm: () => vm.confirmIntake(vm.state.tomas[i].id),
          onPostpone: () => vm.postponeIntake(vm.state.tomas[i].id),
        ),
      );
}

class _TomaCard extends StatelessWidget {
  final Toma toma;
  final VoidCallback onConfirm;
  final VoidCallback onPostpone;

  const _TomaCard({
    required this.toma,
    required this.onConfirm,
    required this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    final hora =
        '${toma.fechaProgramada.hour.toString().padLeft(2, '0')}:${toma.fechaProgramada.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(toma.nombreMedicamento,
                      style: AppTextStyles.heading3),
                ),
                _EstadoChip(estado: toma.estado),
              ],
            ),
            const SizedBox(height: 6),
            Text('${toma.dosis} · $hora',
                style: AppTextStyles.bodySecondary),
            if (toma.esPendiente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onConfirm,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                      ),
                      child: const Text(AppStrings.confirmIntake,
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: onPostpone,
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: AppColors.warning,
                      ),
                      child: const Text(AppStrings.postponeIntake,
                          style: TextStyle(fontSize: 18)),
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

class _EstadoChip extends StatelessWidget {
  final EstadoToma estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      EstadoToma.pendiente => AppColors.textHint,
      EstadoToma.confirmada => AppColors.secondary,
      EstadoToma.omitida => AppColors.error,
      EstadoToma.pospuesta => AppColors.warning,
    };
    return Chip(
      label: Text(estado.label,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
