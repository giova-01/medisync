import 'package:medisync/features/medication/domain/entities/medicamento.dart';

class MedicamentoDto {
  final int id;
  final String nombre;
  final String dosis;
  final int frecuenciaHoras;
  final String fechaInicio;
  final String? fechaFin;

  const MedicamentoDto({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.frecuenciaHoras,
    required this.fechaInicio,
    this.fechaFin,
  });

  factory MedicamentoDto.fromJson(Map<String, dynamic> json) => MedicamentoDto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        dosis: json['dosis'] as String,
        frecuenciaHoras: json['frecuencia_horas'] as int,
        fechaInicio: json['fecha_inicio'] as String,
        fechaFin: json['fecha_fin'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'dosis': dosis,
        'frecuencia_horas': frecuenciaHoras,
        'fecha_inicio': fechaInicio,
        if (fechaFin != null) 'fecha_fin': fechaFin,
      };

  Medicamento toEntity() => Medicamento(
        id: id,
        nombre: nombre,
        dosis: dosis,
        frecuenciaHoras: frecuenciaHoras,
        fechaInicio: DateTime.parse(fechaInicio),
        fechaFin: fechaFin != null ? DateTime.parse(fechaFin!) : null,
      );
}
