import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';

abstract interface class ProfileRepository {
  Future<Either<Failure, Usuario>> getProfile();
  Future<Either<Failure, Usuario>> updateProfile(UpdateProfileParams params);
}

class UpdateProfileParams {
  final String nombre;
  final String apellido;
  final DateTime? fechaNacimiento;
  final List<String>? patologias;
  final String? parentesco;
  final String? matricula;
  final String? especialidad;

  const UpdateProfileParams({
    required this.nombre,
    required this.apellido,
    this.fechaNacimiento,
    this.patologias,
    this.parentesco,
    this.matricula,
    this.especialidad,
  });
}
