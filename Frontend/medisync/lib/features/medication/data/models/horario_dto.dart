import 'package:medisync/features/medication/domain/entities/horario.dart';

class HorarioDto {
  final int id;
  final String horaProgramada;
  final int medicamentoId;

  const HorarioDto({
    required this.id,
    required this.horaProgramada,
    required this.medicamentoId,
  });

  factory HorarioDto.fromJson(Map<String, dynamic> json) => HorarioDto(
        id: json['id'] as int,
        horaProgramada: json['hora_programada'] as String,
        medicamentoId: json['medicamento_id'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'hora_programada': horaProgramada,
        'medicamento_id': medicamentoId,
      };

  Horario toEntity() => Horario(
        id: id,
        horaProgramada: DateTime.parse(horaProgramada),
        medicamentoId: medicamentoId,
      );
}
