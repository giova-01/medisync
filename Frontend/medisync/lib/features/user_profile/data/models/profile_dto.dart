import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/user_profile/domain/entities/cuidador.dart';
import 'package:medisync/features/user_profile/domain/entities/paciente.dart';
import 'package:medisync/features/user_profile/domain/entities/profesional_salud.dart';

/// Richer than [UserDto]: mirrors the backend's `ProfileResponse` (see
/// Backend/app/schemas/profile.py), which carries the per-profile extended
/// fields that `GET/PUT /profile` returns and that `UserDto` cannot hold.
class ProfileDto {
  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final String tipoPerfil;
  final String? fechaNacimiento;
  final String? patologias;
  final String? parentesco;
  final String? matricula;
  final String? especialidad;

  const ProfileDto({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.tipoPerfil,
    this.fechaNacimiento,
    this.patologias,
    this.parentesco,
    this.matricula,
    this.especialidad,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) => ProfileDto(
        id: json['id'] as int,
        email: json['email'] as String,
        nombre: json['nombre'] as String,
        apellido: json['apellido'] as String,
        tipoPerfil: json['tipo_perfil'] as String,
        fechaNacimiento: json['fecha_nacimiento'] as String?,
        patologias: json['patologias'] as String?,
        parentesco: json['parentesco'] as String?,
        matricula: json['matricula'] as String?,
        especialidad: json['especialidad'] as String?,
      );

  Usuario toEntity() {
    final perfil = TipoPerfilX.fromApiValue(tipoPerfil);
    return switch (perfil) {
      TipoPerfil.paciente => Paciente(
          id: id,
          email: email,
          nombre: nombre,
          apellido: apellido,
          tipoPerfil: perfil,
          fechaNacimiento:
              fechaNacimiento != null ? DateTime.parse(fechaNacimiento!) : null,
          patologias: (patologias == null || patologias!.isEmpty)
              ? const []
              : patologias!.split(','),
        ),
      TipoPerfil.cuidador => Cuidador(
          id: id,
          email: email,
          nombre: nombre,
          apellido: apellido,
          tipoPerfil: perfil,
          parentesco: parentesco,
        ),
      TipoPerfil.profesionalSalud => ProfesionalSalud(
          id: id,
          email: email,
          nombre: nombre,
          apellido: apellido,
          tipoPerfil: perfil,
          matricula: matricula,
          especialidad: especialidad,
        ),
    };
  }
}
