// Test de contrato de TE-23: `test/fixtures/sync_catalogo_respuesta.json`
// reproduce una respuesta de `GET /api/sync/catalogo`
// (`obtenerCatalogoSincronizacion`) armada campo por campo según
// `docs/api/openapi.yaml` de `agrocom-api` (develop @ 44570a17): las cinco
// claves `required` de la respuesta, una orden con `lotes[]` de varios
// lotes y `kilos_por_vuelo: null`, otra con `litros_ha: null`, lotes con y
// sin geometría, y un `trabajos[]` con un elemento. Si el contrato cambia,
// se actualiza el fixture contra el `openapi.yaml` nuevo — nunca a la medida
// del parser.

import 'dart:convert';
import 'dart:io';

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/catalogo/catalogo_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

Map<String, dynamic> _fixture() =>
    jsonDecode(
          File('test/fixtures/sync_catalogo_respuesta.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late _ApiClientFalso apiClient;
  late CatalogoRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    apiClient = _ApiClientFalso();
    repositorio = CatalogoRepository(db: db, apiClient: apiClient);
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/sync/catalogo'),
        statusCode: 200,
        data: _fixture(),
      ),
    );
  });

  tearDown(() => db.close());

  test('el fixture tiene todas las claves required de la respuesta', () {
    expect(
      _fixture().keys,
      containsAll(['ordenes', 'lotes', 'personas', 'trabajos', 'cursor']),
    );
  });

  test('pull() parsea la respuesta del contrato sin excepción y deja las '
      'filas esperadas', () async {
    expect(await repositorio.pull(), isTrue);

    final ordenes = await (db.select(
      db.ordenCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(ordenes, hasLength(2));

    final liquida = ordenes[0];
    expect(liquida.contratoId, 1);
    expect(liquida.loteId, 3);
    expect(liquida.cantidadLotes, 3);
    expect(liquida.hectareasSolicitadas, Decimal.parse('300.00'));
    expect(liquida.litrosHa, Decimal.parse('10.00'));
    expect(liquida.kilosPorVuelo, isNull);
    expect(liquida.velocidadMaxKmh, Decimal.parse('25.00'));
    expect(liquida.anchoPasadaM, Decimal.parse('7.00'));
    expect(liquida.observaciones, 'Aplicar en horas de la mañana.');
    expect(liquida.emitidaPorContactoId, 2);
    expect(liquida.fechaEmision, '2026-09-20');
    expect(liquida.estado, 'vigente');
    // drift devuelve hora local: se compara el instante, no la zona.
    expect(
      liquida.updatedAt.isAtSameMomentAs(DateTime.utc(2026, 9, 20, 12)),
      isTrue,
    );

    final solida = ordenes[1];
    expect(solida.loteId, 6);
    expect(solida.cantidadLotes, 1);
    expect(solida.hectareasSolicitadas, Decimal.parse('45.00'));
    expect(solida.litrosHa, isNull);
    expect(solida.kilosPorVuelo, Decimal.parse('8.50'));
    expect(solida.vientoMaxKmh, isNull);
    expect(solida.velocidadMaxKmh, isNull);
    expect(solida.emitidaPorContactoId, isNull);

    final lotes = await (db.select(
      db.loteCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(lotes.map((l) => l.id), [3, 6]);
    expect(lotes[0].propiedadId, 1);
    expect(lotes[0].hectareas, Decimal.parse('120.50'));
    expect(jsonDecode(lotes[0].geometria!), containsPair('type', 'Polygon'));
    expect(lotes[0].restricciones, 'No aplicar cerca del arroyo.');
    expect(lotes[1].geometria, isNull);

    final personas = await (db.select(
      db.personaCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(personas.map((p) => p.rol), ['piloto', 'auxiliar']);
    expect(personas[1].baseId, isNull);

    final trabajo = (await db.select(db.trabajoCatalogo).get()).single;
    expect(trabajo.id, 42);
    expect(trabajo.uuidCliente, '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a');
    expect(trabajo.ordenId, 1);
    expect(trabajo.loteId, 3);
    expect(trabajo.hectareasDeclaradas, Decimal.parse('300.00'));
    expect(trabajo.equipoTrabajoId, 7);

    final cursor = await (db.select(
      db.cursorCatalogo,
    )..where((t) => t.id.equals(0))).getSingle();
    expect(cursor.cursor, _fixture()['cursor']);
  });
}
