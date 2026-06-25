import 'package:dio/dio.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/domain/repositories/auth_repository.dart';
import '../../models/user_dto.dart';

typedef LoginResponse = ({UserDto user, String token});

abstract interface class AuthRemoteDataSource {
  Future<LoginResponse> login(String email, String password);
  Future<LoginResponse> register(RegisterParams params);
  Future<void> recoverPassword(String email);
}

// ---------------------------------------------------------------------------
// Real implementation backed by the FastAPI backend (see Backend/app/routers/auth.py).
// ---------------------------------------------------------------------------
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _api;

  AuthRemoteDataSourceImpl(this._api);

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      return _toLoginResponse(response.data!);
    } on DioException catch (e) {
      _rethrowAsServerException(e);
    }
  }

  @override
  Future<LoginResponse> register(RegisterParams params) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/register',
        body: {
          'nombre': params.nombre,
          'apellido': params.apellido,
          'email': params.email,
          'password': params.password,
          'tipo_perfil': params.tipoPerfil.apiValue,
        },
      );
      return _toLoginResponse(response.data!);
    } on DioException catch (e) {
      _rethrowAsServerException(e);
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    await _api.post<void>('/auth/recover-password', body: {'email': email});
  }

  LoginResponse _toLoginResponse(Map<String, dynamic> json) => (
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );

  Never _rethrowAsServerException(DioException e) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] as String? : null;
    if (detail != null) throw ServerException(detail);
    throw e;
  }
}

// ---------------------------------------------------------------------------
// Mock implementation — replace with real Dio calls once the backend is live.
// Test accounts:
//   paciente@test.com  / Test1234!  → Paciente
//   cuidador@test.com  / Test1234!  → Cuidador
//   profesional@test.com / Test1234! → Profesional de Salud
//   locked@test.com    / *          → throws ServerException (account locked)
// ---------------------------------------------------------------------------
class AuthRemoteDataSourceMock implements AuthRemoteDataSource {
  static const _delay = Duration(milliseconds: 900);

  @override
  Future<LoginResponse> login(String email, String password) async {
    await Future.delayed(_delay);

    if (email == 'locked@test.com') {
      throw const ServerException('ACCOUNT_LOCKED');
    }

    final accounts = _mockAccounts();
    final entry = accounts[email.toLowerCase()];
    if (entry == null || entry.$2 != password) {
      throw const ServerException('INVALID_CREDENTIALS');
    }

    return (user: entry.$1, token: 'mock_jwt_${entry.$1.id}');
  }

  @override
  Future<LoginResponse> register(RegisterParams params) async {
    await Future.delayed(_delay);

    final dto = UserDto(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      email: params.email,
      nombre: params.nombre,
      apellido: params.apellido,
      tipoPerfil: params.tipoPerfil.apiValue,
    );
    return (user: dto, token: 'mock_jwt_${dto.id}');
  }

  @override
  Future<void> recoverPassword(String email) async {
    await Future.delayed(_delay);
    // In the mock we always succeed (simulates email sent).
  }

  static Map<String, (UserDto, String)> _mockAccounts() => {
        'paciente@test.com': (
          const UserDto(
            id: 1,
            email: 'paciente@test.com',
            nombre: 'Juan',
            apellido: 'Pérez',
            tipoPerfil: 'paciente',
          ),
          'Test1234!'
        ),
        'cuidador@test.com': (
          const UserDto(
            id: 2,
            email: 'cuidador@test.com',
            nombre: 'María',
            apellido: 'García',
            tipoPerfil: 'cuidador',
          ),
          'Test1234!'
        ),
        'profesional@test.com': (
          const UserDto(
            id: 3,
            email: 'profesional@test.com',
            nombre: 'Carlos',
            apellido: 'López',
            tipoPerfil: 'profesional_salud',
          ),
          'Test1234!'
        ),
      };
}
