import 'dart:io';

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/evidencia_local.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_sync_engine.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

void main() {
  late AppDatabase db;
  late Directory directorioTemporal;
  late _ApiClientFalso apiClient;
  late EvidenciaSyncEngine motor;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    directorioTemporal = Directory.systemTemp.createTempSync(
      'evidencia_sync_test_',
    );
    apiClient = _ApiClientFalso();
    motor = EvidenciaSyncEngine(apiClient: apiClient, db: db);
  });

  tearDown(() async {
    await db.close();
    if (directorioTemporal.existsSync()) {
      directorioTemporal.deleteSync(recursive: true);
    }
  });

  Future<String> encolar({
    required String uuidCliente,
    String tipo = 'foto_incidencia',
    EstadoEvidenciaLocal estado = EstadoEvidenciaLocal.pendiente,
  }) async {
    final archivo = File('${directorioTemporal.path}/$uuidCliente.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    await db
        .into(db.evidenciaLocal)
        .insert(
          EvidenciaLocalCompanion.insert(
            uuidCliente: uuidCliente,
            tipo: tipo,
            rutaArchivoLocal: archivo.path,
            hashSha256: 'hash-$uuidCliente',
            fecha: DateTime.utc(2026, 9, 11),
            estado: Value(estado),
          ),
        );
    return archivo.path;
  }

  Future<EvidenciaLocalData> filaDe(String uuidCliente) {
    return (db.select(
      db.evidenciaLocal,
    )..where((t) => t.uuidCliente.equals(uuidCliente))).getSingle();
  }

  Response<dynamic> respuestaCon(String estado, {String? motivo}) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/evidencias'),
      statusCode: 200,
      data: {'uuid_cliente': 'x', 'estado': estado, 'motivo': ?motivo},
    );
  }

  test('aplicado marca la fila como subido', () async {
    await encolar(uuidCliente: 'a');
    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => respuestaCon('aplicado'));

    await motor.sincronizar();

    final fila = await filaDe('a');
    expect(fila.estado, EstadoEvidenciaLocal.subido);
    expect(fila.motivoRechazo, isNull);
  });

  test('duplicado se trata igual que aplicado (éxito)', () async {
    await encolar(uuidCliente: 'a');
    when(
      () => apiClient.post(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => respuestaCon('duplicado'));

    await motor.sincronizar();

    expect((await filaDe('a')).estado, EstadoEvidenciaLocal.subido);
  });

  test('rechazado persiste el motivo y no queda pendiente', () async {
    await encolar(uuidCliente: 'a');
    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => respuestaCon('rechazado', motivo: 'hash no coincide'),
    );

    await motor.sincronizar();

    final fila = await filaDe('a');
    expect(fila.estado, EstadoEvidenciaLocal.rechazado);
    expect(fila.motivoRechazo, 'hash no coincide');
  });

  test(
    'un error de red deja la fila pendiente para el próximo ciclo',
    () async {
      await encolar(uuidCliente: 'a');
      when(
        () => apiClient.post(any(), data: any(named: 'data')),
      ).thenThrow(const ApiExcepcionRed());

      await motor.sincronizar();

      expect((await filaDe('a')).estado, EstadoEvidenciaLocal.pendiente);
    },
  );

  test('un error de servidor en una fila no frena la subida de las demás '
      'pendientes del mismo ciclo', () async {
    await encolar(uuidCliente: 'falla');
    await encolar(uuidCliente: 'ok');

    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer((
      invocation,
    ) async {
      final data = invocation.namedArguments[#data] as FormData;
      final uuidField = data.fields.firstWhere((f) => f.key == 'uuid_cliente');
      if (uuidField.value == 'falla') {
        throw const ApiExcepcionServidor(500, null);
      }
      return respuestaCon('aplicado');
    });

    await motor.sincronizar();

    expect((await filaDe('falla')).estado, EstadoEvidenciaLocal.pendiente);
    expect((await filaDe('ok')).estado, EstadoEvidenciaLocal.subido);
  });

  test(
    'arma el FormData con los campos del contrato de POST /api/evidencias',
    () async {
      await encolar(uuidCliente: 'a', tipo: 'captura_rc');
      FormData? dataCapturada;
      when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer((
        invocation,
      ) async {
        dataCapturada = invocation.namedArguments[#data] as FormData;
        return respuestaCon('aplicado');
      });

      await motor.sincronizar();

      Object? campo(String nombre) =>
          dataCapturada!.fields.firstWhere((f) => f.key == nombre).value;
      expect(campo('uuid_cliente'), 'a');
      expect(campo('tipo'), 'captura_rc');
      expect(campo('fecha'), DateTime.utc(2026, 9, 11).toIso8601String());
      expect(campo('hash_dispositivo'), 'hash-a');
      expect(dataCapturada!.files.single.key, 'archivo');
    },
  );

  test('reenviar el mismo lote de pendientes dos veces deja el estado final '
      'idéntico (idempotencia, mismo espíritu que la prueba de replay de '
      'SyncEngine)', () async {
    await encolar(uuidCliente: 'aplicada');
    await encolar(uuidCliente: 'duplicada');
    await encolar(uuidCliente: 'rechazada');

    when(() => apiClient.post(any(), data: any(named: 'data'))).thenAnswer((
      invocation,
    ) async {
      final data = invocation.namedArguments[#data] as FormData;
      final uuid = data.fields.firstWhere((f) => f.key == 'uuid_cliente').value;
      return switch (uuid) {
        'aplicada' => respuestaCon('aplicado'),
        'duplicada' => respuestaCon('duplicado'),
        _ => respuestaCon('rechazado', motivo: 'hash no coincide'),
      };
    });

    await motor.sincronizar();
    final estadosTrasElPrimerCiclo = {
      'aplicada': (await filaDe('aplicada')).estado,
      'duplicada': (await filaDe('duplicada')).estado,
      'rechazada': (await filaDe('rechazada')).estado,
    };

    // Segundo ciclo sobre el MISMO estado: `aplicada`/`duplicada` ya están
    // `subido` y `_leerPendientes` no vuelve a tocarlas; `rechazada` sigue
    // `rechazado` (invariante 6: no se reintenta sola). El resultado debe
    // quedar bit a bit igual al primer ciclo.
    await motor.sincronizar();

    expect(
      (await filaDe('aplicada')).estado,
      estadosTrasElPrimerCiclo['aplicada'],
    );
    expect(
      (await filaDe('duplicada')).estado,
      estadosTrasElPrimerCiclo['duplicada'],
    );
    expect(
      (await filaDe('rechazada')).estado,
      estadosTrasElPrimerCiclo['rechazada'],
    );
    expect((await filaDe('rechazada')).motivoRechazo, 'hash no coincide');
  });
}
