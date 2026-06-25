import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/alerts/domain/entities/alerta.dart';
import 'package:medisync/features/alerts/domain/entities/severidad_alerta.dart';
import 'package:medisync/features/alerts/domain/entities/tipo_alerta.dart';
import 'package:medisync/features/alerts/presentation/viewmodels/alerts_viewmodel.dart';
import 'package:provider/provider.dart';

class AlertCard extends StatelessWidget {
  final Alerta alerta;

  const AlertCard({super.key, required this.alerta});

  Color _colorForSeveridad(SeveridadAlerta s) => switch (s) {
        SeveridadAlerta.info => AppColors.primary,
        SeveridadAlerta.warning => AppColors.warning,
        SeveridadAlerta.critical => AppColors.error,
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForSeveridad(alerta.severidad);
    final vm = context.read<AlertsViewModel>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(alerta.tipo.icon, color: color, size: 32),
        title: Text(
          alerta.titulo,
          style: alerta.leida
              ? AppTextStyles.body
              : AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alerta.mensaje, style: AppTextStyles.bodySecondary),
              const SizedBox(height: 4),
              Text(_relativeTime(alerta.fechaCreacion),
                  style: AppTextStyles.caption),
            ],
          ),
        ),
        trailing: alerta.leida
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        onTap: alerta.leida ? null : () => vm.markAsRead(alerta.id),
      ),
    );
  }
}
