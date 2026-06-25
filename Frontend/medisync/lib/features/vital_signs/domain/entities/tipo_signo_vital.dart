enum TipoSignoVital { frecuenciaCardiaca, saturacionOxigeno, temperatura }

extension TipoSignoVitalX on TipoSignoVital {
  String get label => switch (this) {
        TipoSignoVital.frecuenciaCardiaca => 'Frecuencia Cardíaca',
        TipoSignoVital.saturacionOxigeno => 'Saturación de Oxígeno',
        TipoSignoVital.temperatura => 'Temperatura',
      };

  String get unidad => switch (this) {
        TipoSignoVital.frecuenciaCardiaca => 'bpm',
        TipoSignoVital.saturacionOxigeno => '%',
        TipoSignoVital.temperatura => '°C',
      };

  String get apiValue => switch (this) {
        TipoSignoVital.frecuenciaCardiaca => 'frecuencia_cardiaca',
        TipoSignoVital.saturacionOxigeno => 'saturacion_oxigeno',
        TipoSignoVital.temperatura => 'temperatura',
      };

  static TipoSignoVital fromApiValue(String v) => switch (v) {
        'saturacion_oxigeno' => TipoSignoVital.saturacionOxigeno,
        'temperatura' => TipoSignoVital.temperatura,
        _ => TipoSignoVital.frecuenciaCardiaca,
      };

  // Rangos clínicos de referencia (adulto mayor en reposo) usados para
  // colorear la UI — normal / warning / critical.
  (double, double) get rangoNormal => switch (this) {
        TipoSignoVital.frecuenciaCardiaca => (60, 100),
        TipoSignoVital.saturacionOxigeno => (95, 100),
        TipoSignoVital.temperatura => (36.0, 37.5),
      };

  (double, double) get rangoWarning => switch (this) {
        TipoSignoVital.frecuenciaCardiaca => (50, 120),
        TipoSignoVital.saturacionOxigeno => (90, 95),
        TipoSignoVital.temperatura => (35.0, 38.5),
      };
}
