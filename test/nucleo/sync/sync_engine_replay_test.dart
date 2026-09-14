// Prueba de replay obligatoria (invariante 10 de CLAUDE.md / skill
// `verificacion`): aplicar el mismo lote de sincronización repetidas veces,
// en orden y en desorden parcial, tiene que dejar el estado final de
// `ColaSync` idéntico siempre. Se escribe antes de la primera pantalla del
// esqueleto vertical — no es un test opcional ni se puede simular.
//
// El caso real que esto cubre: el dispositivo pierde la respuesta de
// `POST /api/sync` después de que el servidor ya aplicó el lote (corte de
// señal en el camino de vuelta, o el proceso muere entre recibir la
// respuesta y ejecutar el `UPDATE` local) — las filas quedan `pendiente` en
// el mismo outbox, y el próximo ciclo las reenvía contra el mismo
// `ColaSync`. Por eso los dos tests de acá reenvían sobre una única base
// `drift` persistente entre corridas (nunca una base nueva por corrida:
// eso solo probaría reproducibilidad entre ejecuciones aisladas, no
// idempotencia frente a reintento).
//
// El servidor simulado ([_ServidorSyncFalso]) se comporta como el real:
// idempotente por `uuid_cliente` (el mismo uuid ya aplicado responde
// `duplicado` la segunda vez) y evalúa el rechazo en cada intento, sin
// memoria de intentos previos rechazados — igual que el servidor real, que
// no persiste nada de un registro que no aplicó.

import 'dart:convert';

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/sync/outbox_repository.dart';
import 'package:agrocom_field/nucleo/sync/sync_engine.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
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
  final Map<String, int> _vecesAplicado = {};

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
      _vecesAplicado.update(uuidCliente, (v) => v + 1, ifAbsent: () => 1);
      return {'uuid_cliente': uuidCliente, 'tipo': tipo, 'estado': 'aplicado'};
    }).toList();
    return {'resultados': resultados};
  }

  /// Cuántas veces este [uuidCliente] pasó de no-aplicado a `aplicado`.
  /// Tiene que quedar en 1 aunque el lote se reenvíe muchas veces — es lo
  /// que prueba que reenviar no duplica nada del lado persistente.
  int vecesAplicado(String uuidCliente) => _vecesAplicado[uuidCliente] ?? 0;
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

/// Simula que el `UPDATE` local de `marcarConfirmado`/`marcarRechazado`
/// nunca llegó a persistir (el dispositivo no se enteró de la respuesta
/// anterior): las filas vuelven a `pendiente` aunque el servidor ya las
/// procesó, para que el próximo `sincronizar()` las reenvíe contra el mismo
/// `ColaSync`. Bypassea `OutboxRepository` a propósito — es el fallo externo
/// que la invariante 10 exige tolerar, no una llamada legítima del motor.
Future<void> _reinyectarComoPendiente(
  AppDatabase db,
  List<String> uuidsCliente,
) async {
  for (final uuidCliente in uuidsCliente) {
    await (db.update(
      db.colaSync,
    )..where((t) => t.uuidCliente.equals(uuidCliente))).write(
      const ColaSyncCompanion(
        estado: Value(EstadoSync.pendiente),
        motivoRechazo: Value(null),
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
    test('mismo lote sembrado una vez, reenviado 10 veces sobre la misma base, '
        'converge sin duplicar del lado servidor', () async {
      final servidor = _ServidorSyncFalso();
      final db = AppDatabase(NativeDatabase.memory());
      final outbox = OutboxRepository(db);
      final motor = SyncEngine(
        apiClient: _clienteContra(servidor),
        outbox: outbox,
      );
      final todosLosUuids = _loteFijo.map((r) => r.uuidCliente).toList();

      await _sembrar(db, _loteFijo);

      final estadosFinales = <Map<String, Map<String, Object?>>>[];
      for (var corrida = 0; corrida < 10; corrida++) {
        if (corrida > 0) {
          await _reinyectarComoPendiente(db, todosLosUuids);
        }
        await motor.sincronizar();
        estadosFinales.add(await _estadoFinal(db));
      }

      motor.dispose();
      await db.close();

      for (final estado in estadosFinales) {
        expect(estado, estadosFinales.first);
      }
      expect(estadosFinales.first['t1']!['estado'], 'confirmado');
      expect(estadosFinales.first['s1']!['estado'], 'confirmado');
      expect(estadosFinales.first['r1']!['estado'], 'confirmado');
      expect(estadosFinales.first['x1']!['estado'], 'rechazado');

      // Las otras 9 corridas llegaron como `duplicado`: reenviar el lote
      // no duplicó nada del lado servidor.
      expect(servidor.vecesAplicado('t1'), 1);
      expect(servidor.vecesAplicado('s1'), 1);
      expect(servidor.vecesAplicado('r1'), 1);
      expect(servidor.vecesAplicado('x1'), 0);
    });

    test(
      'mismo lote en sub-lotes, en orden A→B y B→A, reenviado repetidas '
      'veces sobre la misma base, converge siempre al mismo estado final',
      () async {
        final grupoA = _loteFijo.sublist(0, 2); // trabajo, sesion
        final grupoB = _loteFijo.sublist(2); // recarga, sesion rechazada
        final todosLosUuids = _loteFijo.map((r) => r.uuidCliente).toList();
        final ordenes = [
          [grupoA, grupoB],
          [grupoB, grupoA],
        ];

        final estadosFinalesPorOrden = <Map<String, Map<String, Object?>>>[];

        for (final orden in ordenes) {
          final servidor = _ServidorSyncFalso();
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

          final estadosFinales = <Map<String, Map<String, Object?>>>[
            await _estadoFinal(db),
          ];
          for (var corrida = 1; corrida < 10; corrida++) {
            await _reinyectarComoPendiente(db, todosLosUuids);
            await motor.sincronizar();
            estadosFinales.add(await _estadoFinal(db));
          }

          motor.dispose();
          await db.close();

          for (final estado in estadosFinales) {
            expect(estado, estadosFinales.first);
          }
          expect(servidor.vecesAplicado('t1'), 1);
          expect(servidor.vecesAplicado('s1'), 1);
          expect(servidor.vecesAplicado('r1'), 1);
          expect(servidor.vecesAplicado('x1'), 0);

          estadosFinalesPorOrden.add(estadosFinales.first);
        }

        // El orden de llegada de los sub-lotes no cambia el estado final.
        expect(estadosFinalesPorOrden[0], estadosFinalesPorOrden[1]);
        expect(estadosFinalesPorOrden.first['t1']!['estado'], 'confirmado');
        expect(estadosFinalesPorOrden.first['s1']!['estado'], 'confirmado');
        expect(estadosFinalesPorOrden.first['r1']!['estado'], 'confirmado');
        expect(estadosFinalesPorOrden.first['x1']!['estado'], 'rechazado');
      },
    );
  });
}
