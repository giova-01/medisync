import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/vital_signs/domain/entities/nivel_signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';

class VitalHistoryChart extends StatelessWidget {
  final List<SignoVital> history;
  final TipoSignoVital tipo;

  const VitalHistoryChart({super.key, required this.history, required this.tipo});

  Color _colorForNivel(NivelSignoVital nivel) => switch (nivel) {
        NivelSignoVital.normal => AppColors.primary,
        NivelSignoVital.warning => AppColors.vitalsWarning,
        NivelSignoVital.critical => AppColors.vitalsCritical,
      };

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noHistoryData,
          style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center,
        ),
      );
    }

    final sorted = [...history]..sort((a, b) => a.fechaMedicion.compareTo(b.fechaMedicion));
    final (warnMin, warnMax) = tipo.rangoWarning;
    final minY = [warnMin, ...sorted.map((s) => s.valor)].reduce((a, b) => a < b ? a : b) - 2;
    final maxY = [warnMax, ...sorted.map((s) => s.valor)].reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(horizontalInterval: null, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) =>
                  Text(value.toStringAsFixed(0), style: AppTextStyles.caption),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (sorted.length / 4).clamp(1, sorted.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                final hora = sorted[i].fechaMedicion;
                final hh = hora.hour.toString().padLeft(2, '0');
                final mm = hora.minute.toString().padLeft(2, '0');
                return Text('$hh:$mm', style: AppTextStyles.caption);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < sorted.length; i++) FlSpot(i.toDouble(), sorted[i].valor),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: _colorForNivel(sorted[index].nivel),
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
