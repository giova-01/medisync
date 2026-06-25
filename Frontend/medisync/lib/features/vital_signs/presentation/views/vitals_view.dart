import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';
import 'package:medisync/features/vital_signs/presentation/viewmodels/vitals_viewmodel.dart';
import 'package:medisync/features/vital_signs/presentation/views/widgets/vital_history_chart.dart';
import 'package:medisync/features/vital_signs/presentation/views/widgets/vital_reading_card.dart';
import 'package:provider/provider.dart';

class VitalsView extends StatefulWidget {
  const VitalsView({super.key});

  @override
  State<VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<VitalsView> {
  Failure? _shownFailure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<VitalsViewModel>();
      vm.loadLatest();
      vm.startLiveUpdates();
    });
  }

  @override
  void dispose() {
    context.read<VitalsViewModel>().stopLiveUpdates();
    super.dispose();
  }

  void _maybeShowError(BuildContext context, VitalsState state) {
    final failure = state.failure;
    if (failure == null || failure == _shownFailure) return;
    _shownFailure = failure;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      context.read<VitalsViewModel>().clearFailure();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VitalsViewModel>();
    final state = vm.state;
    _maybeShowError(context, state);

    if (state.isLoading && state.latest.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, color: AppColors.secondary, size: 18),
              const SizedBox(width: 6),
              Text(AppStrings.liveUpdating, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final tipo in TipoSignoVital.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: VitalReadingCard(tipo: tipo, signo: state.latest[tipo]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(AppStrings.last24Hours, style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final tipo in TipoSignoVital.values)
                ChoiceChip(
                  label: Text(tipo.label),
                  selected: state.selectedTipo == tipo,
                  onSelected: (_) => vm.selectTipo(tipo),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: VitalHistoryChart(history: state.history, tipo: state.selectedTipo),
          ),
        ],
      ),
    );
  }
}
