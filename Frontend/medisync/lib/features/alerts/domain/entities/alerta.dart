import 'package:medisync/features/alerts/domain/entities/severidad_alerta.dart';
import 'package:medisync/features/alerts/domain/entities/tipo_alerta.dart';

class Alerta {
  final int id;
  final TipoAlerta tipo;
  final SeveridadAlerta severidad;
  final String titulo;
  final String mensaje;
  final DateTime fechaCreacion;
  final bool leida;

  const Alerta({
    required this.id,
    required this.tipo,
    required this.severidad,
    required this.titulo,
    required this.mensaje,
    required this.fechaCreacion,
    this.leida = false,
  });

  Alerta marcarLeida() => Alerta(
        id: id,
        tipo: tipo,
        severidad: severidad,
        titulo: titulo,
        mensaje: mensaje,
        fechaCreacion: fechaCreacion,
        leida: true,
      );
}
