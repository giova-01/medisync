enum TipoPerfil { paciente, cuidador, profesionalSalud }

extension TipoPerfilX on TipoPerfil {
  String get label => switch (this) {
        TipoPerfil.paciente => 'Paciente',
        TipoPerfil.cuidador => 'Cuidador',
        TipoPerfil.profesionalSalud => 'Profesional de Salud',
      };

  /// Value sent to / received from the backend.
  String get apiValue => switch (this) {
        TipoPerfil.paciente => 'paciente',
        TipoPerfil.cuidador => 'cuidador',
        TipoPerfil.profesionalSalud => 'profesional_salud',
      };

  static TipoPerfil fromApiValue(String value) => switch (value) {
        'cuidador' => TipoPerfil.cuidador,
        'profesional_salud' => TipoPerfil.profesionalSalud,
        _ => TipoPerfil.paciente,
      };
}

class Usuario {
  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final TipoPerfil tipoPerfil;

  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.tipoPerfil,
  });

  String get nombreCompleto => '$nombre $apellido';
}
