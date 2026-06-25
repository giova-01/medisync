import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/vital_signs/domain/entities/nivel_signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';

class VitalReadingCard extends StatelessWidget {
  final TipoSignoVital tipo;
  final SignoVital? signo;

  const VitalReadingCard({super.key, required this.tipo, this.signo});

  Color _colorForNivel(NivelSignoVital nivel) => switch (nivel) {
        NivelSignoVital.normal => AppColors.vitalsNormal,
        NivelSignoVital.warning => AppColors.vitalsWarning,
        NivelSignoVital.critical => AppColors.vitalsCritical,
      };

  IconData get _icon => switch (tipo) {
        TipoSignoVital.frecuenciaCardiaca => Icons.favorite,
        TipoSignoVital.saturacionOxigeno => Icons.air,
        TipoSignoVital.temperatura => Icons.thermostat,
      };

  @override
  Widget build(BuildContext context) {
    final color = signo != null ? _colorForNivel(signo!.nivel) : AppColors.textHint;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              signo != null ? signo!.valor.toStringAsFixed(1) : '--',
              style: AppTextStyles.heading2.copyWith(fontSize: 28, color: color),
            ),
            Text(tipo.unidad, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              tipo.label,
              style: AppTextStyles.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
