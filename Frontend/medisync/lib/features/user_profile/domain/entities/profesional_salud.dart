import 'package:medisync/features/auth/domain/entities/usuario.dart';

class ProfesionalSalud extends Usuario {
  final String? matricula;
  final String? especialidad;

  const ProfesionalSalud({
    required super.id,
    required super.email,
    required super.nombre,
    required super.apellido,
    required super.tipoPerfil,
    this.matricula,
    this.especialidad,
  });
}
