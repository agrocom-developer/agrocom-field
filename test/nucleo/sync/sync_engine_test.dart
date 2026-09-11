import 'dart:convert';

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/sync/estado_sync.dart';
import 'package:agrocom_field/nucleo/sync/outbox_repository.dart';
import 'package:agrocom_field/nucleo/sync/sync_engine.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late _ApiClientFalso apiClient;
  late SyncEngine motor;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    apiClient = _ApiClientFalso();
    motor = SyncEngine(apiClient: apiClient, outbox: outbox);
  });

  tearDown(() async {
    motor.dispose();
    await db.close();
  });

  Future<void> encolar({
    required String uuidCliente,
    required String tipoEntidad,
    required int secuencia,
    Map<String, dynamic> payload = const {},
  }) {
    return db
        .into(db.colaSync)
        .insert(
          ColaSyncCompanion.insert(
            uuidCliente: uuidCliente,
            tipoEntidad: tipoEntidad,
            payload: jsonEncode(payload),
            secuencia: secuencia,
          ),
        );
  }

  Future<EstadoSync> estadoDe(String uuidCliente) async {
    final fila = await (db.select(
      db.colaSync,
    )..where((t) => t.uuidCliente.equals(uuidCliente))).getSingle();
    return fila.estado;
  }

  Response<dynamic> respuestaCon(List<Map<String, dynamic>> resultados) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/sync'),
      statusCode: 200,
      data: {'resultados': resultados},
    );
  }

  // `estado` es un stream broadcast (entrega asíncrona): hay que darle una
  // vuelta de event loop después de `sincronizar()` para que el último
  // evento llegue al listener antes de cancelar la suscripción.
  Future<List<EstadoMotorSync>> sincronizarYCapturarEstados() async {
    final estados = <EstadoMotorSync>[];
    final sub = motor.estado.listen(estados.add);
    await motor.sincronizar();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return estados;
  }

  test('un lote con aplicado, duplicado y rechazado mezclados avanza cada '
      'fila según corresponda, sin que el rechazo frene al resto', () async {
    await encolar(uuidCliente: 'a', tipoEntidad: 'trabajo', secuencia: 1);
    await encolar(uuidCliente: 'b', tipoEntidad: 'sesion', secuencia: 2);
    await encolar(uuidCliente: 'c', tipoEntidad: 'sesion', secuencia: 3);

    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => respuestaCon([
        {'uuid_cliente': 'a', 'tipo': 'trabajo', 'estado': 'aplicado'},
        {'uuid_cliente': 'b', 'tipo': 'sesion', 'estado': 'duplicado'},
        {
          'uuid_cliente': 'c',
          'tipo': 'sesion',
          'estado': 'rechazado',
          'motivo': 'el trabajo referenciado no existe todavía',
        },
      ]),
    );

    final estados = await sincronizarYCapturarEstados();

    expect(await estadoDe('a'), EstadoSync.confirmado);
    expect(await estadoDe('b'), EstadoSync.confirmado);
    expect(await estadoDe('c'), EstadoSync.rechazado);
    expect(estados, [EstadoMotorSync.sincronizando, EstadoMotorSync.ocioso]);
  });

  test('ApiExcepcionRed deja las filas pendiente y el motor vuelve a ocioso '
      '(no es un error, es el caso normal en el lote)', () async {
    await encolar(uuidCliente: 'a', tipoEntidad: 'trabajo', secuencia: 1);

    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenThrow(const ApiExcepcionRed());

    final estados = await sincronizarYCapturarEstados();

    expect(await estadoDe('a'), EstadoSync.pendiente);
    expect(estados, [EstadoMotorSync.sincronizando, EstadoMotorSync.ocioso]);
  });

  test('ApiExcepcionServidor deja las filas intactas y emite error', () async {
    await encolar(uuidCliente: 'a', tipoEntidad: 'trabajo', secuencia: 1);

    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenThrow(const ApiExcepcionServidor(500, null));

    final estados = await sincronizarYCapturarEstados();

    expect(await estadoDe('a'), EstadoSync.pendiente);
    expect(estados, [EstadoMotorSync.sincronizando, EstadoMotorSync.error]);
  });

  test(
    'ApiExcepcionDesconocida deja las filas intactas y emite error',
    () async {
      await encolar(uuidCliente: 'a', tipoEntidad: 'trabajo', secuencia: 1);

      when(
        () => apiClient.post(any(), data: any(named: 'data')),
      ).thenThrow(ApiExcepcionDesconocida(Exception('lo que sea')));

      final estados = await sincronizarYCapturarEstados();

      expect(await estadoDe('a'), EstadoSync.pendiente);
      expect(estados, [EstadoMotorSync.sincronizando, EstadoMotorSync.error]);
    },
  );

  test(
    'arma cada registro con tipo, uuid_cliente y los campos del payload',
    () async {
      await encolar(
        uuidCliente: 'a',
        tipoEntidad: 'trabajo',
        secuencia: 1,
        payload: {'orden_id': 1, 'lote_id': 3, 'nro_aplicacion': 1},
      );

      Object? dataCapturada;
      when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer((
        invocation,
      ) async {
        dataCapturada = invocation.namedArguments[#data];
        return respuestaCon([
          {'uuid_cliente': 'a', 'tipo': 'trabajo', 'estado': 'aplicado'},
        ]);
      });

      await motor.sincronizar();

      expect(dataCapturada, {
        'registros': [
          {
            'tipo': 'trabajo',
            'uuid_cliente': 'a',
            'orden_id': 1,
            'lote_id': 3,
            'nro_aplicacion': 1,
          },
        ],
      });
    },
  );
}
