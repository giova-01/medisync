import 'package:medisync/features/auth/domain/entities/usuario.dart';

class Cuidador extends Usuario {
  final String? parentesco;

  const Cuidador({
    required super.id,
    required super.email,
    required super.nombre,
    required super.apellido,
    required super.tipoPerfil,
    this.parentesco,
  });
}
