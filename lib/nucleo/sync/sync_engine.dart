import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import '../db/database.dart';
import 'estado_sync.dart';
import 'outbox_repository.dart';

/// Motor de sync offline-first (ADR 0005 de `agrocom-api`, invariantes 1 a 7
/// y 10 de `CLAUDE.md`). Vive en `nucleo/`, sin BLoC: corre disparado por
/// conectividad, apertura de app o botón manual, y publica su estado por
/// [estado] para que un `SyncCubit` (capa de presentación, fuera de este
/// archivo) lo exponga a la UI.
///
/// Solo implementa el push (`POST /api/sync`, TE-05) sobre las filas
/// `pendiente` del outbox ([OutboxRepository]) — el pull de catálogo
/// (`GET /api/sync/catalogo`) es TE-06, fuera de este motor.
class SyncEngine {
  SyncEngine({required ApiClient apiClient, required OutboxRepository outbox})
    : _apiClient = apiClient,
      _outbox = outbox;

  final ApiClient _apiClient;
  final OutboxRepository _outbox;

  final _controladorEstado = StreamController<EstadoMotorSync>.broadcast();

  /// Estado del motor completo (no confundir con el `EstadoSync` de cada fila
  /// del outbox, ver `estado_sync.dart`).
  Stream<EstadoMotorSync> get estado => _controladorEstado.stream;

  /// Dispara un ciclo de push: lee el outbox, lo manda completo a
  /// `POST /api/sync` y avanza el estado de cada fila según la respuesta.
  /// Quien invoca este método decide el trigger (conectividad recuperada,
  /// apertura de app, botón manual) — acá no hay temporizadores ni reintentos
  /// con backoff, el ciclo corre una sola vez por llamada.
  Future<void> sincronizar() async {
    _controladorEstado.add(EstadoMotorSync.sincronizando);

    final pendientes = await _outbox.leerPendientes();
    final registros = pendientes.map(_registroDesdeFila).toList();

    final Response<dynamic> respuesta;
    try {
      respuesta = await _apiClient.post(
        '/api/sync',
        data: {'registros': registros},
      );
    } on ApiExcepcionRed {
      // Sin señal ahora — no es un error del motor (ver api_excepcion.dart):
      // las filas quedan `pendiente`, listas para el próximo ciclo.
      _controladorEstado.add(EstadoMotorSync.ocioso);
      return;
    } on ApiExcepcion {
      // Servidor/desconocida: sin una respuesta parseada no hay forma de
      // saber qué aplicó el servidor, así que el outbox no se toca.
      _controladorEstado.add(EstadoMotorSync.error);
      return;
    }

    final resultados =
        (respuesta.data as Map<String, dynamic>)['resultados'] as List;
    for (final crudo in resultados) {
      final resultado = crudo as Map<String, dynamic>;
      final uuidCliente = resultado['uuid_cliente'] as String;
      switch (resultado['estado'] as String) {
        case 'aplicado':
        case 'duplicado':
          await _outbox.marcarConfirmado(uuidCliente);
        case 'rechazado':
          await _outbox.marcarRechazado(
            uuidCliente,
            resultado['motivo'] as String,
          );
      }
    }

    _controladorEstado.add(EstadoMotorSync.ocioso);
  }

  Map<String, dynamic> _registroDesdeFila(ColaSyncData fila) {
    final payload = jsonDecode(fila.payload) as Map<String, dynamic>;
    return {
      'tipo': fila.tipoEntidad,
      'uuid_cliente': fila.uuidCliente,
      ...payload,
    };
  }

  void dispose() {
    _controladorEstado.close();
  }
}
