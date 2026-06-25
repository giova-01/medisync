import 'package:medisync/features/auth/domain/entities/usuario.dart';

class Paciente extends Usuario {
  final DateTime? fechaNacimiento;
  final List<String> patologias;

  const Paciente({
    required super.id,
    required super.email,
    required super.nombre,
    required super.apellido,
    required super.tipoPerfil,
    this.fechaNacimiento,
    this.patologias = const [],
  });
}
