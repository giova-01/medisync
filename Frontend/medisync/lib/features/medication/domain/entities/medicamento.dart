class Medicamento {
  final int id;
  final String nombre;
  final String dosis;
  final int frecuenciaHoras;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  const Medicamento({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.frecuenciaHoras,
    required this.fechaInicio,
    this.fechaFin,
  });
}
