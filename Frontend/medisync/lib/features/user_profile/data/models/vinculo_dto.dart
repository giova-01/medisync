import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';

class VinculoDto {
  final int id;
  final int idPaciente;
  final int idUsuarioVinculado;
  final String emailUsuarioVinculado;
  final String nombreUsuarioVinculado;
  final String apellidoUsuarioVinculado;
  final String tipoVinculo;
  final String estado;

  const VinculoDto({
    required this.id,
    required this.idPaciente,
    required this.idUsuarioVinculado,
    required this.emailUsuarioVinculado,
    required this.nombreUsuarioVinculado,
    required this.apellidoUsuarioVinculado,
    required this.tipoVinculo,
    required this.estado,
  });

  factory VinculoDto.fromJson(Map<String, dynamic> json) => VinculoDto(
        id: json['id'] as int,
        idPaciente: json['id_paciente'] as int,
        idUsuarioVinculado: json['id_usuario_vinculado'] as int,
        emailUsuarioVinculado: json['email_usuario_vinculado'] as String,
        nombreUsuarioVinculado: json['nombre_usuario_vinculado'] as String,
        apellidoUsuarioVinculado: json['apellido_usuario_vinculado'] as String,
        tipoVinculo: json['tipo_vinculo'] as String,
        estado: json['estado'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_paciente': idPaciente,
        'id_usuario_vinculado': idUsuarioVinculado,
        'email_usuario_vinculado': emailUsuarioVinculado,
        'nombre_usuario_vinculado': nombreUsuarioVinculado,
        'apellido_usuario_vinculado': apellidoUsuarioVinculado,
        'tipo_vinculo': tipoVinculo,
        'estado': estado,
      };

  Vinculo toEntity() {
    final tipo = TipoVinculoX.fromApiValue(tipoVinculo);
    return Vinculo(
      id: id,
      idPaciente: idPaciente,
      usuarioVinculado: Usuario(
        id: idUsuarioVinculado,
        email: emailUsuarioVinculado,
        nombre: nombreUsuarioVinculado,
        apellido: apellidoUsuarioVinculado,
        tipoPerfil: tipo == TipoVinculo.cuidador
            ? TipoPerfil.cuidador
            : TipoPerfil.profesionalSalud,
      ),
      tipoVinculo: tipo,
      estado: EstadoVinculoX.fromApiValue(estado),
    );
  }
}
