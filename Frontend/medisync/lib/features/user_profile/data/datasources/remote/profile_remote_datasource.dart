import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:medisync/features/user_profile/data/models/profile_dto.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';

abstract interface class ProfileRemoteDataSource {
  Future<ProfileDto> getProfile();
  Future<ProfileDto> updateProfile(UpdateProfileParams params);
}

class ProfileRemoteDataSourceMock implements ProfileRemoteDataSource {
  static const _delay = Duration(milliseconds: 700);

  final AuthLocalDataSource _local;

  ProfileRemoteDataSourceMock(this._local);

  @override
  Future<ProfileDto> getProfile() async {
    await Future.delayed(_delay);
    final cached = await _local.readUser();
    if (cached != null) {
      return ProfileDto(
        id: cached.id,
        email: cached.email,
        nombre: cached.nombre,
        apellido: cached.apellido,
        tipoPerfil: cached.tipoPerfil,
      );
    }
    return const ProfileDto(
      id: 1,
      email: 'paciente@test.com',
      nombre: 'Juan',
      apellido: 'Pérez',
      tipoPerfil: 'paciente',
    );
  }

  @override
  Future<ProfileDto> updateProfile(UpdateProfileParams params) async {
    await Future.delayed(_delay);
    final current = await _local.readUser();
    return ProfileDto(
      id: current?.id ?? 1,
      email: current?.email ?? '',
      nombre: params.nombre,
      apellido: params.apellido,
      tipoPerfil: current?.tipoPerfil ?? 'paciente',
      fechaNacimiento: params.fechaNacimiento?.toIso8601String().substring(0, 10),
      patologias: params.patologias?.join(','),
      parentesco: params.parentesco,
      matricula: params.matricula,
      especialidad: params.especialidad,
    );
  }
}

// ---------------------------------------------------------------------------
// Real implementation backed by the FastAPI backend (see Backend/app/routers/profile.py).
// ---------------------------------------------------------------------------
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _api;

  ProfileRemoteDataSourceImpl(this._api);

  @override
  Future<ProfileDto> getProfile() async {
    final response = await _api.get<Map<String, dynamic>>('/profile');
    return ProfileDto.fromJson(response.data!);
  }

  @override
  Future<ProfileDto> updateProfile(UpdateProfileParams params) async {
    final response = await _api.put<Map<String, dynamic>>('/profile', body: {
      'nombre': params.nombre,
      'apellido': params.apellido,
      'fecha_nacimiento': params.fechaNacimiento?.toIso8601String().substring(0, 10),
      'patologias': params.patologias?.join(','),
      'parentesco': params.parentesco,
      'matricula': params.matricula,
      'especialidad': params.especialidad,
    });
    return ProfileDto.fromJson(response.data!);
  }
}
