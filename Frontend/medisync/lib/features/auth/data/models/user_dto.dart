import 'package:medisync/features/auth/domain/entities/usuario.dart';

class UserDto {
  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final String tipoPerfil;

  const UserDto({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.tipoPerfil,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as int,
        email: json['email'] as String,
        nombre: json['nombre'] as String,
        apellido: json['apellido'] as String,
        tipoPerfil: json['tipo_perfil'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        'tipo_perfil': tipoPerfil,
      };

  Usuario toEntity() => Usuario(
        id: id,
        email: email,
        nombre: nombre,
        apellido: apellido,
        tipoPerfil: TipoPerfilX.fromApiValue(tipoPerfil),
      );
}
