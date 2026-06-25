import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/core/network/token_local_datasource.dart';
import 'package:medisync/features/vital_signs/data/models/signo_vital_dto.dart';
import 'package:medisync/features/vital_signs/domain/entities/tipo_signo_vital.dart';
import 'package:medisync/features/vital_signs/domain/repositories/vital_signs_repository.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class VitalsRemoteDataSource {
  Future<List<SignoVitalDto>> getLatestReadings();
  Future<List<SignoVitalDto>> getHistory(GetHistoryParams params);
  Stream<SignoVitalDto> watchLiveReadings();
}

class VitalsRemoteDataSourceMock implements VitalsRemoteDataSource {
  final _random = Random();

  @override
  Future<List<SignoVitalDto>> getLatestReadings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      _generate(TipoSignoVital.frecuenciaCardiaca, now),
      _generate(TipoSignoVital.saturacionOxigeno, now),
      _generate(TipoSignoVital.temperatura, now),
    ];
  }

  @override
  Future<List<SignoVitalDto>> getHistory(GetHistoryParams params) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final readings = <SignoVitalDto>[];
    var current = params.from;
    var id = 1;
    while (current.isBefore(params.to)) {
      readings.add(_generate(params.tipo, current, id: id++));
      current = current.add(const Duration(minutes: 30));
    }
    return readings;
  }

  @override
  Stream<SignoVitalDto> watchLiveReadings() async* {
    var id = 1000;
    final tipos = TipoSignoVital.values;
    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      final tipo = tipos[_random.nextInt(tipos.length)];
      yield _generate(tipo, DateTime.now(), id: id++);
    }
  }

  SignoVitalDto _generate(TipoSignoVital tipo, DateTime fecha, {int id = 0}) {
    final (min, max) = tipo.rangoNormal;
    final base = min + _random.nextDouble() * (max - min);
    final spike = _random.nextDouble() < 0.15
        ? (_random.nextBool() ? 1 : -1) * (max - min) * 0.4
        : 0.0;
    final valor = base + spike;
    return SignoVitalDto(
      id: id,
      tipo: tipo.apiValue,
      valor: double.parse(valor.toStringAsFixed(1)),
      fechaMedicion: fecha.toIso8601String(),
    );
  }
}

// ---------------------------------------------------------------------------
// Real implementation backed by the FastAPI backend (see
// Backend/app/routers/vital_signs.py). The live stream connects to the
// `/vital-signs/live` WebSocket, authenticated via `?token=` query param
// (the backend route reads it the same way, not from a header).
// ---------------------------------------------------------------------------
class VitalsRemoteDataSourceImpl implements VitalsRemoteDataSource {
  final ApiClient _api;
  final TokenLocalDataSource _tokenDS;
  final String _baseUrl;

  VitalsRemoteDataSourceImpl(this._api, this._tokenDS, this._baseUrl);

  @override
  Future<List<SignoVitalDto>> getLatestReadings() async {
    final response = await _api.get<List<dynamic>>('/vital-signs/latest');
    return (response.data ?? [])
        .map((e) => SignoVitalDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SignoVitalDto>> getHistory(GetHistoryParams params) async {
    final response = await _api.get<List<dynamic>>('/vital-signs/history', query: {
      'tipo': params.tipo.apiValue,
      'from': params.from.toIso8601String(),
      'to': params.to.toIso8601String(),
    });
    return (response.data ?? [])
        .map((e) => SignoVitalDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<SignoVitalDto> watchLiveReadings() {
    WebSocketChannel? channel;
    late StreamController<SignoVitalDto> controller;
    controller = StreamController<SignoVitalDto>(
      onListen: () async {
        final token = await _tokenDS.readToken();
        if (token == null) {
          controller.addError(StateError('NOT_AUTHENTICATED'));
          await controller.close();
          return;
        }
        channel = WebSocketChannel.connect(_liveUri('/vital-signs/live', token));
        channel!.stream.listen(
          (event) {
            final json = jsonDecode(event as String) as Map<String, dynamic>;
            controller.add(SignoVitalDto.fromJson(json));
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => channel?.sink.close(),
    );
    return controller.stream;
  }

  Uri _liveUri(String path, String token) {
    final httpUri = Uri.parse(_baseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    return httpUri.replace(
      scheme: wsScheme,
      path: '${httpUri.path}$path',
      queryParameters: {'token': token},
    );
  }
}
