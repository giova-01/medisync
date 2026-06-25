import 'package:flutter/material.dart';

enum TipoAlerta { tomaOmitida, signoVitalCritico, vinculoSolicitado, recordatorioToma }

extension TipoAlertaX on TipoAlerta {
  String get apiValue => switch (this) {
        TipoAlerta.tomaOmitida => 'toma_omitida',
        TipoAlerta.signoVitalCritico => 'signo_vital_critico',
        TipoAlerta.vinculoSolicitado => 'vinculo_solicitado',
        TipoAlerta.recordatorioToma => 'recordatorio_toma',
      };

  IconData get icon => switch (this) {
        TipoAlerta.tomaOmitida => Icons.medication_liquid,
        TipoAlerta.signoVitalCritico => Icons.monitor_heart,
        TipoAlerta.vinculoSolicitado => Icons.link,
        TipoAlerta.recordatorioToma => Icons.alarm,
      };

  static TipoAlerta fromApiValue(String v) => switch (v) {
        'signo_vital_critico' => TipoAlerta.signoVitalCritico,
        'vinculo_solicitado' => TipoAlerta.vinculoSolicitado,
        'recordatorio_toma' => TipoAlerta.recordatorioToma,
        _ => TipoAlerta.tomaOmitida,
      };
}
