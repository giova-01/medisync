import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/core/network/token_local_datasource.dart';
import 'package:medisync/features/alerts/data/models/alerta_dto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class NotificationDataSource {
  Future<List<AlertaDto>> getAlerts();
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
  Stream<AlertaDto> watchNewAlerts();
}

// Mock — sin Firebase. Mantiene una lista en memoria con alertas
// iniciales y simula push periódico generando una alerta nueva cada
// 30-60 segundos, alternando tipo y severidad. Será reemplazado por
// una implementación FCM real cuando el backend y Firebase estén listos.
class NotificationDataSourceMock implements NotificationDataSource {
  final _random = Random();
  final List<AlertaDto> _alerts = [
    AlertaDto(
      id: 1,
      tipo: 'toma_omitida',
      severidad: 'warning',
      titulo: 'Toma omitida',
      mensaje: 'Se omitió la toma de Enalapril 10mg programada a las 08:00.',
      fechaCreacion:
          DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      leida: false,
    ),
    AlertaDto(
      id: 2,
      tipo: 'signo_vital_critico',
      severidad: 'critical',
      titulo: 'Saturación de oxígeno baja',
      mensaje:
          'Se registró una saturación de oxígeno de 88%, por debajo del rango seguro.',
      fechaCreacion:
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      leida: false,
    ),
    AlertaDto(
      id: 3,
      tipo: 'recordatorio_toma',
      severidad: 'info',
      titulo: 'Próxima toma',
      mensaje: 'Tenés una toma de Metformina 500mg en 15 minutos.',
      fechaCreacion: DateTime.now()
          .subtract(const Duration(minutes: 10))
          .toIso8601String(),
      leida: true,
    ),
  ];
  int _nextId = 4;

  @override
  Future<List<AlertaDto>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_alerts);
  }

  @override
  Future<void> markAsRead(int id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx] = AlertaDto(
        id: _alerts[idx].id,
        tipo: _alerts[idx].tipo,
        severidad: _alerts[idx].severidad,
        titulo: _alerts[idx].titulo,
        mensaje: _alerts[idx].mensaje,
        fechaCreacion: _alerts[idx].fechaCreacion,
        leida: true,
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _alerts.length; i++) {
      _alerts[i] = AlertaDto(
        id: _alerts[i].id,
        tipo: _alerts[i].tipo,
        severidad: _alerts[i].severidad,
        titulo: _alerts[i].titulo,
        mensaje: _alerts[i].mensaje,
        fechaCreacion: _alerts[i].fechaCreacion,
        leida: true,
      );
    }
  }

  @override
  Stream<AlertaDto> watchNewAlerts() async* {
    final tipos = ['toma_omitida', 'signo_vital_critico', 'recordatorio_toma'];
    final mensajes = {
      'toma_omitida': 'Se omitió una toma programada.',
      'signo_vital_critico': 'Se detectó un signo vital fuera de rango seguro.',
      'recordatorio_toma': 'Tenés una toma programada próximamente.',
    };
    while (true) {
      await Future.delayed(Duration(seconds: 30 + _random.nextInt(30)));
      final tipo = tipos[_random.nextInt(tipos.length)];
      final severidad = tipo == 'signo_vital_critico'
          ? 'critical'
          : tipo == 'toma_omitida'
              ? 'warning'
              : 'info';
      final dto = AlertaDto(
        id: _nextId++,
        tipo: tipo,
        severidad: severidad,
        titulo: tipo == 'signo_vital_critico'
            ? 'Signo vital crítico'
            : tipo == 'toma_omitida'
                ? 'Toma omitida'
                : 'Recordatorio',
        mensaje: mensajes[tipo]!,
        fechaCreacion: DateTime.now().toIso8601String(),
        leida: false,
      );
      _alerts.insert(0, dto);
      yield dto;
    }
  }
}

// ---------------------------------------------------------------------------
// Real implementation backed by the FastAPI backend (see
// Backend/app/routers/alerts.py). The live stream connects to the
// `/alerts/live` WebSocket, authenticated via `?token=` query param.
// ---------------------------------------------------------------------------
class NotificationDataSourceImpl implements NotificationDataSource {
  final ApiClient _api;
  final TokenLocalDataSource _tokenDS;
  final String _baseUrl;

  NotificationDataSourceImpl(this._api, this._tokenDS, this._baseUrl);

  @override
  Future<List<AlertaDto>> getAlerts() async {
    final response = await _api.get<List<dynamic>>('/alerts');
    return (response.data ?? [])
        .map((e) => AlertaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(int id) async {
    await _api.post<void>('/alerts/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _api.post<void>('/alerts/read-all');
  }

  @override
  Stream<AlertaDto> watchNewAlerts() {
    WebSocketChannel? channel;
    late StreamController<AlertaDto> controller;
    controller = StreamController<AlertaDto>(
      onListen: () async {
        final token = await _tokenDS.readToken();
        if (token == null) {
          controller.addError(StateError('NOT_AUTHENTICATED'));
          await controller.close();
          return;
        }
        channel = WebSocketChannel.connect(_liveUri('/alerts/live', token));
        channel!.stream.listen(
          (event) {
            final json = jsonDecode(event as String) as Map<String, dynamic>;
            controller.add(AlertaDto.fromJson(json));
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
