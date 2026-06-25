import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';
import '../entities/usuario.dart';

abstract interface class AuthRepository {
  /// Authenticates the user and persists the JWT locally.
  Future<Either<Failure, Usuario>> login(String email, String password);

  /// Creates a new account with the given profile type.
  Future<Either<Failure, Usuario>> register(RegisterParams params);

  /// Sends a password-reset email.
  Future<Either<Failure, void>> recoverPassword(String email);

  /// Clears the local JWT and invalidates the session.
  Future<Either<Failure, void>> logout();

  /// Returns the locally cached user, or null if no session exists.
  Future<Either<Failure, Usuario?>> currentUser();
}

class RegisterParams {
  final String nombre;
  final String apellido;
  final String email;
  final String password;
  final TipoPerfil tipoPerfil;

  const RegisterParams({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.password,
    required this.tipoPerfil,
  });
}
