import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/medication/domain/entities/toma.dart';
import 'package:medisync/features/medication/presentation/viewmodels/intakes_viewmodel.dart';
import 'package:provider/provider.dart';

class CuidadorPacienteView extends StatefulWidget {
  const CuidadorPacienteView({super.key});

  @override
  State<CuidadorPacienteView> createState() => _CuidadorPacienteViewState();
}

class _CuidadorPacienteViewState extends State<CuidadorPacienteView> {
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
      appBar: AppBar(title: const Text(AppStrings.patientView)),
      body: vm.state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.state.tomas.isEmpty
              ? _emptyState()
              : _tomasList(vm.state.tomas),
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

  Widget _tomasList(List<Toma> tomas) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tomas.length,
        itemBuilder: (_, i) => _TomaReadonlyCard(toma: tomas[i]),
      );
}

class _TomaReadonlyCard extends StatelessWidget {
  final Toma toma;
  const _TomaReadonlyCard({required this.toma});

  @override
  Widget build(BuildContext context) {
    final hora =
        '${toma.fechaProgramada.hour.toString().padLeft(2, '0')}:${toma.fechaProgramada.minute.toString().padLeft(2, '0')}';
    final color = switch (toma.estado) {
      EstadoToma.pendiente => AppColors.textHint,
      EstadoToma.confirmada => AppColors.secondary,
      EstadoToma.omitida => AppColors.error,
      EstadoToma.pospuesta => AppColors.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(toma.nombreMedicamento, style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text('${toma.dosis} · $hora',
                      style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            Chip(
              label: Text(toma.estado.label,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 14)),
              backgroundColor: color,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
