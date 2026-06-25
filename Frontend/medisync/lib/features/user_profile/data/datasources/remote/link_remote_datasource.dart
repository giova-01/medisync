import 'package:dio/dio.dart';
import 'package:medisync/core/errors/exceptions.dart';
import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/features/user_profile/data/models/vinculo_dto.dart';
import 'package:medisync/features/user_profile/domain/entities/vinculo.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';

abstract interface class LinkRemoteDataSource {
  Future<VinculoDto> requestLink(RequestLinkParams params);
  Future<VinculoDto> respondLink(RespondLinkParams params);
  Future<List<VinculoDto>> listLinks();
  Future<void> revokeLink(int vinculoId);
}

class LinkRemoteDataSourceMock implements LinkRemoteDataSource {
  static const _delay = Duration(milliseconds: 700);

  final _mockLinks = <VinculoDto>[
    const VinculoDto(
      id: 1,
      idPaciente: 1,
      idUsuarioVinculado: 2,
      emailUsuarioVinculado: 'cuidador@test.com',
      nombreUsuarioVinculado: 'María',
      apellidoUsuarioVinculado: 'García',
      tipoVinculo: 'cuidador',
      estado: 'pendiente',
    ),
    const VinculoDto(
      id: 2,
      idPaciente: 1,
      idUsuarioVinculado: 3,
      emailUsuarioVinculado: 'profesional@test.com',
      nombreUsuarioVinculado: 'Carlos',
      apellidoUsuarioVinculado: 'López',
      tipoVinculo: 'profesional_salud',
      estado: 'aceptado',
    ),
  ];

  int _nextId = 10;

  @override
  Future<VinculoDto> requestLink(RequestLinkParams params) async {
    await Future.delayed(_delay);
    if (!params.targetEmail.contains('@')) {
      throw const ServerException('EMAIL_NOT_FOUND');
    }
    final dto = VinculoDto(
      id: _nextId++,
      idPaciente: 1,
      idUsuarioVinculado: 99,
      emailUsuarioVinculado: params.targetEmail,
      nombreUsuarioVinculado: params.targetEmail.split('@').first,
      apellidoUsuarioVinculado: '',
      tipoVinculo: params.rol.apiValue,
      estado: 'pendiente',
    );
    _mockLinks.add(dto);
    return dto;
  }

  @override
  Future<VinculoDto> respondLink(RespondLinkParams params) async {
    await Future.delayed(_delay);
    final index = _mockLinks.indexWhere((v) => v.id == params.vinculoId);
    if (index == -1) throw const ServerException('VINCULO_NOT_FOUND');
    final original = _mockLinks[index];
    final updated = VinculoDto(
      id: original.id,
      idPaciente: original.idPaciente,
      idUsuarioVinculado: original.idUsuarioVinculado,
      emailUsuarioVinculado: original.emailUsuarioVinculado,
      nombreUsuarioVinculado: original.nombreUsuarioVinculado,
      apellidoUsuarioVinculado: original.apellidoUsuarioVinculado,
      tipoVinculo: original.tipoVinculo,
      estado: params.aceptar ? EstadoVinculo.aceptado.apiValue : EstadoVinculo.rechazado.apiValue,
    );
    _mockLinks[index] = updated;
    return updated;
  }

  @override
  Future<List<VinculoDto>> listLinks() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_mockLinks);
  }

  @override
  Future<void> revokeLink(int vinculoId) async {
    await Future.delayed(_delay);
    final index = _mockLinks.indexWhere((v) => v.id == vinculoId);
    if (index == -1) throw const ServerException('VINCULO_NOT_FOUND');
    final original = _mockLinks[index];
    _mockLinks[index] = VinculoDto(
      id: original.id,
      idPaciente: original.idPaciente,
      idUsuarioVinculado: original.idUsuarioVinculado,
      emailUsuarioVinculado: original.emailUsuarioVinculado,
      nombreUsuarioVinculado: original.nombreUsuarioVinculado,
      apellidoUsuarioVinculado: original.apellidoUsuarioVinculado,
      tipoVinculo: original.tipoVinculo,
      estado: EstadoVinculo.revocado.apiValue,
    );
  }
}

// ---------------------------------------------------------------------------
// Real implementation backed by the FastAPI backend (see Backend/app/routers/links.py).
// ---------------------------------------------------------------------------
class LinkRemoteDataSourceImpl implements LinkRemoteDataSource {
  final ApiClient _api;

  LinkRemoteDataSourceImpl(this._api);

  @override
  Future<VinculoDto> requestLink(RequestLinkParams params) async {
    try {
      final response = await _api.post<Map<String, dynamic>>('/links/request', body: {
        'target_email': params.targetEmail,
        'rol': params.rol.apiValue,
      });
      return VinculoDto.fromJson(response.data!);
    } on DioException catch (e) {
      _rethrowAsServerException(e);
    }
  }

  @override
  Future<VinculoDto> respondLink(RespondLinkParams params) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/links/${params.vinculoId}/respond',
        body: {'aceptar': params.aceptar},
      );
      return VinculoDto.fromJson(response.data!);
    } on DioException catch (e) {
      _rethrowAsServerException(e);
    }
  }

  @override
  Future<List<VinculoDto>> listLinks() async {
    final response = await _api.get<List<dynamic>>('/links');
    return (response.data ?? [])
        .map((e) => VinculoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> revokeLink(int vinculoId) async {
    try {
      await _api.delete<void>('/links/$vinculoId');
    } on DioException catch (e) {
      _rethrowAsServerException(e);
    }
  }

  Never _rethrowAsServerException(DioException e) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] as String? : null;
    if (detail != null) throw ServerException(detail);
    throw e;
  }
}
