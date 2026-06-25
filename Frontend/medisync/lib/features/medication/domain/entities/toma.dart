enum EstadoToma { pendiente, confirmada, omitida, pospuesta }

extension EstadoTomaX on EstadoToma {
  String get label => switch (this) {
        EstadoToma.pendiente => 'Pendiente',
        EstadoToma.confirmada => 'Confirmada',
        EstadoToma.omitida => 'Omitida',
        EstadoToma.pospuesta => 'Pospuesta',
      };

  String get apiValue => switch (this) {
        EstadoToma.pendiente => 'pendiente',
        EstadoToma.confirmada => 'confirmada',
        EstadoToma.omitida => 'omitida',
        EstadoToma.pospuesta => 'pospuesta',
      };

  static EstadoToma fromApiValue(String v) => switch (v) {
        'confirmada' => EstadoToma.confirmada,
        'omitida' => EstadoToma.omitida,
        'pospuesta' => EstadoToma.pospuesta,
        _ => EstadoToma.pendiente,
      };
}

class Toma {
  final int id;
  final DateTime fechaProgramada;
  final DateTime? fechaConfirmada;
  final EstadoToma estado;
  final int horarioId;
  final String nombreMedicamento;
  final String dosis;

  const Toma({
    required this.id,
    required this.fechaProgramada,
    this.fechaConfirmada,
    required this.estado,
    required this.horarioId,
    required this.nombreMedicamento,
    required this.dosis,
  });

  bool get esPendiente =>
      estado == EstadoToma.pendiente || estado == EstadoToma.pospuesta;
}
