import 'package:medisync/features/alerts/domain/entities/alerta.dart';
import 'package:medisync/features/alerts/domain/entities/severidad_alerta.dart';
import 'package:medisync/features/alerts/domain/entities/tipo_alerta.dart';

class AlertaDto {
  final int id;
  final String tipo;
  final String severidad;
  final String titulo;
  final String mensaje;
  final String fechaCreacion;
  final bool leida;

  const AlertaDto({
    required this.id,
    required this.tipo,
    required this.severidad,
    required this.titulo,
    required this.mensaje,
    required this.fechaCreacion,
    this.leida = false,
  });

  factory AlertaDto.fromJson(Map<String, dynamic> json) => AlertaDto(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        severidad: json['severidad'] as String,
        titulo: json['titulo'] as String,
        mensaje: json['mensaje'] as String,
        fechaCreacion: json['fecha_creacion'] as String,
        leida: json['leida'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'severidad': severidad,
        'titulo': titulo,
        'mensaje': mensaje,
        'fecha_creacion': fechaCreacion,
        'leida': leida,
      };

  Alerta toEntity() => Alerta(
        id: id,
        tipo: TipoAlertaX.fromApiValue(tipo),
        severidad: SeveridadAlertaX.fromApiValue(severidad),
        titulo: titulo,
        mensaje: mensaje,
        fechaCreacion: DateTime.parse(fechaCreacion),
        leida: leida,
      );
}
