import 'package:medisync/features/auth/domain/entities/usuario.dart';

enum TipoVinculo { cuidador, profesionalSalud }

extension TipoVinculoX on TipoVinculo {
  String get label => switch (this) {
        TipoVinculo.cuidador => 'Cuidador',
        TipoVinculo.profesionalSalud => 'Profesional de Salud',
      };

  String get apiValue => switch (this) {
        TipoVinculo.cuidador => 'cuidador',
        TipoVinculo.profesionalSalud => 'profesional_salud',
      };

  static TipoVinculo fromApiValue(String value) => switch (value) {
        'profesional_salud' => TipoVinculo.profesionalSalud,
        _ => TipoVinculo.cuidador,
      };
}

enum EstadoVinculo { pendiente, aceptado, rechazado, revocado }

extension EstadoVinculoX on EstadoVinculo {
  String get label => switch (this) {
        EstadoVinculo.pendiente => 'Pendiente',
        EstadoVinculo.aceptado => 'Aceptado',
        EstadoVinculo.rechazado => 'Rechazado',
        EstadoVinculo.revocado => 'Revocado',
      };

  String get apiValue => switch (this) {
        EstadoVinculo.pendiente => 'pendiente',
        EstadoVinculo.aceptado => 'aceptado',
        EstadoVinculo.rechazado => 'rechazado',
        EstadoVinculo.revocado => 'revocado',
      };

  static EstadoVinculo fromApiValue(String value) => switch (value) {
        'aceptado' => EstadoVinculo.aceptado,
        'rechazado' => EstadoVinculo.rechazado,
        'revocado' => EstadoVinculo.revocado,
        _ => EstadoVinculo.pendiente,
      };
}

class Vinculo {
  final int id;
  final int idPaciente;
  final Usuario usuarioVinculado;
  final TipoVinculo tipoVinculo;
  final EstadoVinculo estado;

  const Vinculo({
    required this.id,
    required this.idPaciente,
    required this.usuarioVinculado,
    required this.tipoVinculo,
    required this.estado,
  });

  bool get esPendiente => estado == EstadoVinculo.pendiente;
  bool get esActivo => estado == EstadoVinculo.aceptado;
}
