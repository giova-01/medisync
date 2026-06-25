import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/medication/domain/entities/medicamento.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';
import 'package:medisync/features/medication/presentation/viewmodels/schedule_viewmodel.dart';
import 'package:provider/provider.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleViewModel>().loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();

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
      appBar: AppBar(title: const Text(AppStrings.myMedications)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, vm, null),
        child: const Icon(Icons.add),
      ),
      body: vm.state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.state.medications.isEmpty
              ? _emptyState()
              : _medicationList(context, vm),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_pharmacy_outlined,
                size: 72, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text(AppStrings.myMedications, style: AppTextStyles.bodySecondary),
          ],
        ),
      );

  Widget _medicationList(BuildContext context, ScheduleViewModel vm) =>
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.state.medications.length,
        itemBuilder: (_, i) {
          final med = vm.state.medications[i];
          return _MedCard(
            medicamento: med,
            onEdit: () => _showForm(context, vm, med),
            onDelete: () => _confirmDelete(context, vm, med),
          );
        },
      );

  Future<void> _showForm(
      BuildContext context, ScheduleViewModel vm, Medicamento? med) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _MedicamentoForm(editing: med),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ScheduleViewModel vm, Medicamento med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteMedication,
            style: AppTextStyles.heading3),
        content: Text(
            '${AppStrings.confirmDeleteMedication}\n\n${med.nombre} ${med.dosis}',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Eliminar', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await vm.removeMedication(med.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.medicationDeleted)),
        );
      }
    }
  }
}

class _MedCard extends StatelessWidget {
  final Medicamento medicamento;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedCard({
    required this.medicamento,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fin = medicamento.fechaFin;
    final finStr = fin != null
        ? '${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')}/${fin.year}'
        : 'Sin fecha de fin';
    final inicioStr =
        '${medicamento.fechaInicio.day.toString().padLeft(2, '0')}/${medicamento.fechaInicio.month.toString().padLeft(2, '0')}/${medicamento.fechaInicio.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${medicamento.nombre} · ${medicamento.dosis}',
                    style: AppTextStyles.heading3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 28),
                  tooltip: AppStrings.editMedication,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 28, color: AppColors.error),
                  tooltip: AppStrings.deleteMedication,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${AppStrings.frequencyLabel} ${medicamento.frecuenciaHoras} ${AppStrings.frequencyHours}',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 4),
            Text('Inicio: $inicioStr  ·  Fin: $finStr',
                style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}

class _MedicamentoForm extends StatefulWidget {
  final Medicamento? editing;
  const _MedicamentoForm({this.editing});

  @override
  State<_MedicamentoForm> createState() => _MedicamentoFormState();
}

class _MedicamentoFormState extends State<_MedicamentoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _dosis;
  late final TextEditingController _frecuencia;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    final med = widget.editing;
    _nombre = TextEditingController(text: med?.nombre ?? '');
    _dosis = TextEditingController(text: med?.dosis ?? '');
    _frecuencia = TextEditingController(
        text: med != null ? med.frecuenciaHoras.toString() : '');
    _fechaInicio = med?.fechaInicio;
    _fechaFin = med?.fechaFin;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _dosis.dispose();
    _frecuencia.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Seleccionar';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _fechaInicio : _fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seleccioná una fecha de inicio',
                style: TextStyle(fontSize: 18))),
      );
      return;
    }

    final vm = context.read<ScheduleViewModel>();
    final frecuencia = int.parse(_frecuencia.text.trim());
    final med = widget.editing;

    if (med == null) {
      await vm.addMedication(AddMedicamentoParams(
        nombre: _nombre.text.trim(),
        dosis: _dosis.text.trim(),
        frecuenciaHoras: frecuencia,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin,
      ));
    } else {
      await vm.updateMedication(UpdateMedicamentoParams(
        id: med.id,
        nombre: _nombre.text.trim(),
        dosis: _dosis.text.trim(),
        frecuenciaHoras: frecuencia,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin,
      ));
    }

    if (!mounted) return;
    if (vm.state.saveSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.medicationSaved)),
      );
      vm.clearSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    final vm = context.watch<ScheduleViewModel>();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? AppStrings.editMedication
                    : AppStrings.addMedication,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombre,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                    labelText: AppStrings.medicationName),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? AppStrings.nameTooShort
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosis,
                style: AppTextStyles.body,
                decoration:
                    const InputDecoration(labelText: AppStrings.medicationDose),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppStrings.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frecuencia,
                style: AppTextStyles.body,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: AppStrings.medicationFrequency),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 24) {
                    return 'Ingresá un valor entre 1 y 24';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.medicationStartDate,
                    style: AppTextStyles.body),
                subtitle: Text(_formatDate(_fechaInicio),
                    style: AppTextStyles.bodySecondary),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.medicationEndDate,
                    style: AppTextStyles.body),
                subtitle: Text(_formatDate(_fechaFin),
                    style: AppTextStyles.bodySecondary),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: vm.state.isLoading ? null : _save,
                  child: vm.state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(AppStrings.saveMedication,
                          style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
