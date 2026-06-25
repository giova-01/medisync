import 'package:medisync/features/medication/domain/entities/toma.dart';

class TomaDto {
  final int id;
  final String fechaProgramada;
  final String? fechaConfirmada;
  final String estado;
  final int horarioId;
  final String nombreMedicamento;
  final String dosis;

  const TomaDto({
    required this.id,
    required this.fechaProgramada,
    this.fechaConfirmada,
    required this.estado,
    required this.horarioId,
    required this.nombreMedicamento,
    required this.dosis,
  });

  factory TomaDto.fromJson(Map<String, dynamic> json) => TomaDto(
        id: json['id'] as int,
        fechaProgramada: json['fecha_programada'] as String,
        fechaConfirmada: json['fecha_confirmada'] as String?,
        estado: json['estado'] as String,
        horarioId: json['horario_id'] as int,
        nombreMedicamento: json['nombre_medicamento'] as String,
        dosis: json['dosis'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha_programada': fechaProgramada,
        if (fechaConfirmada != null) 'fecha_confirmada': fechaConfirmada,
        'estado': estado,
        'horario_id': horarioId,
        'nombre_medicamento': nombreMedicamento,
        'dosis': dosis,
      };

  Toma toEntity() => Toma(
        id: id,
        fechaProgramada: DateTime.parse(fechaProgramada),
        fechaConfirmada:
            fechaConfirmada != null ? DateTime.parse(fechaConfirmada!) : null,
        estado: EstadoTomaX.fromApiValue(estado),
        horarioId: horarioId,
        nombreMedicamento: nombreMedicamento,
        dosis: dosis,
      );
}
