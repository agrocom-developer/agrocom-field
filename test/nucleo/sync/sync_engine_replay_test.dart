// Prueba de replay obligatoria (invariante 10 de CLAUDE.md / skill
// `verificacion`): aplicar el mismo lote de sincronización repetidas veces,
// en orden y en desorden parcial, tiene que dejar el estado final de
// `ColaSync` idéntico siempre. Se escribe antes de la primera pantalla del
// esqueleto vertical — no es un test opcional ni se puede simular.
//
// El servidor simulado ([_ServidorSyncFalso]) se comporta como el real:
// idempotente por `uuid_cliente` (el mismo uuid ya aplicado responde
// `duplicado` la segunda vez) y evalúa el rechazo en cada intento, sin
// memoria de intentos previos rechazados — igual que el servidor real, que
// no persiste nada de un registro que no aplicó.

import 'dart:convert';

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/sync/outbox_repository.dart';
import 'package:agrocom_field/nucleo/sync/sync_engine.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

class _RegistroFijo {
  const _RegistroFijo({
    required this.uuidCliente,
    required this.tipoEntidad,
    required this.secuencia,
    required this.payload,
  });

  final String uuidCliente;
  final String tipoEntidad;
  final int secuencia;
  final Map<String, dynamic> payload;
}

/// El mismo lote lógico (trabajo -> sesión -> recarga, más un registro que
/// el servidor simulado siempre rechaza) que se reaplica en cada corrida.
const _loteFijo = [
  _RegistroFijo(
    uuidCliente: 't1',
    tipoEntidad: 'trabajo',
    secuencia: 1,
    payload: {'orden_id': 1, 'lote_id': 3, 'nro_aplicacion': 1},
  ),
  _RegistroFijo(
    uuidCliente: 's1',
    tipoEntidad: 'sesion',
    secuencia: 2,
    payload: {'trabajo_uuid_cliente': 't1', 'piloto_id': 5},
  ),
  _RegistroFijo(
    uuidCliente: 'r1',
    tipoEntidad: 'recarga',
    secuencia: 3,
    payload: {'sesion_uuid_cliente': 's1'},
  ),
  _RegistroFijo(
    uuidCliente: 'x1',
    tipoEntidad: 'sesion',
    secuencia: 4,
    payload: {'sesion_uuid_cliente': 's1', 'rechazar': true},
  ),
];

/// Idempotente por `uuid_cliente`, como el servidor real (espec §2.1): un
/// `uuid_cliente` ya aplicado responde `duplicado`, nunca se reaplica.
class _ServidorSyncFalso {
  final Set<String> _aplicados = {};

  Map<String, dynamic> procesar(Map<String, dynamic> body) {
    final registros = (body['registros'] as List).cast<Map<String, dynamic>>();
    final resultados = registros.map((registro) {
      final uuidCliente = registro['uuid_cliente'] as String;
      final tipo = registro['tipo'] as String;
      if (registro['rechazar'] == true) {
        return {
          'uuid_cliente': uuidCliente,
          'tipo': tipo,
          'estado': 'rechazado',
          'motivo': 'condición inválida (simulada)',
        };
      }
      if (_aplicados.contains(uuidCliente)) {
        return {
          'uuid_cliente': uuidCliente,
          'tipo': tipo,
          'estado': 'duplicado',
        };
      }
      _aplicados.add(uuidCliente);
      return {'uuid_cliente': uuidCliente, 'tipo': tipo, 'estado': 'aplicado'};
    }).toList();
    return {'resultados': resultados};
  }
}

_ApiClientFalso _clienteContra(_ServidorSyncFalso servidor) {
  final cliente = _ApiClientFalso();
  when(() => cliente.post(any(), data: any(named: 'data'))).thenAnswer((
    invocation,
  ) async {
    final body = invocation.namedArguments[#data] as Map<String, dynamic>;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/sync'),
      statusCode: 200,
      data: servidor.procesar(body),
    );
  });
  return cliente;
}

Future<void> _sembrar(AppDatabase db, List<_RegistroFijo> registros) async {
  for (final registro in registros) {
    await db
        .into(db.colaSync)
        .insert(
          ColaSyncCompanion.insert(
            uuidCliente: registro.uuidCliente,
            tipoEntidad: registro.tipoEntidad,
            payload: jsonEncode(registro.payload),
            secuencia: registro.secuencia,
          ),
        );
  }
}

/// Estado final de `ColaSync`, por `uuidCliente` — lo que la prueba de
/// replay compara entre corridas.
Future<Map<String, Map<String, Object?>>> _estadoFinal(AppDatabase db) async {
  final filas = await db.select(db.colaSync).get();
  return {
    for (final fila in filas)
      fila.uuidCliente: {
        'estado': fila.estado.name,
        'motivoRechazo': fila.motivoRechazo,
      },
  };
}

void main() {
  group('sync engine replay (invariante 10 de CLAUDE.md)', () {
    test(
      'mismo lote 10 veces seguidas, en orden, deja ColaSync idéntica en cada corrida',
      () async {
        final servidor = _ServidorSyncFalso();
        final estadosFinales = <Map<String, Map<String, Object?>>>[];

        for (var corrida = 0; corrida < 10; corrida++) {
          final db = AppDatabase(NativeDatabase.memory());
          final outbox = OutboxRepository(db);
          final motor = SyncEngine(
            apiClient: _clienteContra(servidor),
            outbox: outbox,
          );

          await _sembrar(db, _loteFijo);
          await motor.sincronizar();

          estadosFinales.add(await _estadoFinal(db));

          motor.dispose();
          await db.close();
        }

        for (final estado in estadosFinales) {
          expect(estado, estadosFinales.first);
        }
        expect(estadosFinales.first['t1']!['estado'], 'confirmado');
        expect(estadosFinales.first['s1']!['estado'], 'confirmado');
        expect(estadosFinales.first['r1']!['estado'], 'confirmado');
        expect(estadosFinales.first['x1']!['estado'], 'rechazado');
      },
    );

    test('mismo lote dividido en sub-lotes, mandados en distinto orden entre '
        'corridas, deja ColaSync idéntica siempre', () async {
      final servidor = _ServidorSyncFalso();
      final grupoA = _loteFijo.sublist(0, 2); // trabajo, sesion
      final grupoB = _loteFijo.sublist(2); // recarga, sesion rechazada
      final ordenes = [
        [grupoA, grupoB],
        [grupoB, grupoA],
      ];

      final estadosFinales = <Map<String, Map<String, Object?>>>[];

      for (var corrida = 0; corrida < 10; corrida++) {
        final orden = ordenes[corrida % ordenes.length];
        final db = AppDatabase(NativeDatabase.memory());
        final outbox = OutboxRepository(db);
        final motor = SyncEngine(
          apiClient: _clienteContra(servidor),
          outbox: outbox,
        );

        for (final subLote in orden) {
          await _sembrar(db, subLote);
          await motor.sincronizar();
        }

        estadosFinales.add(await _estadoFinal(db));

        motor.dispose();
        await db.close();
      }

      for (final estado in estadosFinales) {
        expect(estado, estadosFinales.first);
      }
      expect(estadosFinales.first['t1']!['estado'], 'confirmado');
      expect(estadosFinales.first['s1']!['estado'], 'confirmado');
      expect(estadosFinales.first['r1']!['estado'], 'confirmado');
      expect(estadosFinales.first['x1']!['estado'], 'rechazado');
    });
  });
}
