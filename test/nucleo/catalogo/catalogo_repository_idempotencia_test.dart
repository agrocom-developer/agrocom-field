// Etapa 3 de TE-06: prueba de idempotencia del pull de catálogo — "el mismo
// lote de sync aplicado varias veces, en orden y con cursores repetidos, deja
// la base local idéntica" (mismo principio que la prueba de replay del push
// en `sync_engine_replay_test.dart`, invariante 10 de CLAUDE.md, aplicado al
// lado de lectura del motor de sync).

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/catalogo/catalogo_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

Map<String, dynamic> _ordenJson({
  required int id,
  required String estado,
  required String updatedAt,
  int loteId = 3,
}) => {
  'id': id,
  'contrato_id': 1,
  'lote_id': loteId,
  'nro_aplicacion': 1,
  'litros_ha': '10.00',
  'humedad_min_pct': null,
  'viento_max_kmh': null,
  'temperatura_max_c': null,
  'humedad_max_pct': null,
  'velocidad_max_kmh': null,
  'altura_vuelo_m': null,
  'velocidad_vuelo_kmh': null,
  'ancho_pasada_m': null,
  'observaciones': null,
  'emitida_por_contacto_id': null,
  'fecha_emision': '2026-08-26',
  'estado': estado,
  'updated_at': updatedAt,
};

Map<String, dynamic> _cuerpo({
  List<Map<String, dynamic>> ordenes = const [],
  List<Map<String, dynamic>> lotes = const [],
  List<Map<String, dynamic>> personas = const [],
  required String cursor,
}) => {
  'ordenes': ordenes,
  'lotes': lotes,
  'personas': personas,
  'cursor': cursor,
};

/// Servidor fake indexado por el `desde` recibido (`null` = primera
/// sincronización, ausente en la query) — como el real, cada página depende
/// del cursor que el cliente reenvía, no de cuántas veces ya se llamó.
class _ServidorCatalogoFalso {
  _ServidorCatalogoFalso(this._paginas);

  final Map<String?, Map<String, dynamic>> _paginas;

  Response<dynamic> responder(Invocation invocacion) {
    final query = invocacion.namedArguments[#query] as Map<String, dynamic>?;
    final desde = query?['desde'] as String?;
    final cuerpo = _paginas[desde];
    if (cuerpo == null) {
      throw StateError('el servidor fake no tiene página para desde=$desde');
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/sync/catalogo'),
      statusCode: 200,
      data: cuerpo,
    );
  }
}

_ApiClientFalso _clienteContra(_ServidorCatalogoFalso servidor) {
  final cliente = _ApiClientFalso();
  when(
    () => cliente.get(any(), query: any(named: 'query')),
  ).thenAnswer((invocacion) async => servidor.responder(invocacion));
  return cliente;
}

Future<String?> _cursorGuardado(AppDatabase db) async {
  final fila = await (db.select(
    db.cursorCatalogo,
  )..where((t) => t.id.equals(0))).getSingleOrNull();
  return fila?.cursor;
}

void main() {
  group('pull de catálogo — idempotencia (invariante 10 de CLAUDE.md)', () {
    test(
      'el mismo pull corrido dos veces con el mismo cursor no duplica filas',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        // El servidor fake devuelve exactamente la misma página para el
        // mismo `desde` las dos veces que se la pide — nada cambió del lado
        // servidor entre un pull y el reintento (o el disparo manual extra).
        final servidor = _ServidorCatalogoFalso({
          null: _cuerpo(
            ordenes: [
              _ordenJson(
                id: 1,
                estado: 'vigente',
                updatedAt: '2026-08-26T12:00:00+00:00',
              ),
            ],
            cursor: 'c1',
          ),
          'c1': _cuerpo(
            ordenes: [
              _ordenJson(
                id: 1,
                estado: 'vigente',
                updatedAt: '2026-08-26T12:00:00+00:00',
              ),
            ],
            cursor: 'c1',
          ),
        });
        final repositorio = CatalogoRepository(
          db: db,
          apiClient: _clienteContra(servidor),
        );

        await repositorio.pull();
        await repositorio.pull();

        final ordenes = await db.select(db.ordenCatalogo).get();
        expect(ordenes, hasLength(1));
        expect(ordenes.single.id, 1);
        expect(ordenes.single.estado, 'vigente');

        expect(await _cursorGuardado(db), 'c1');
      },
    );

    test('pulls sucesivos con cursores distintos acumulan: filas nuevas se '
        'agregan, filas repetidas se actualizan, nunca se duplican', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final servidor = _ServidorCatalogoFalso({
        null: _cuerpo(
          ordenes: [
            _ordenJson(
              id: 1,
              estado: 'vigente',
              updatedAt: '2026-08-26T12:00:00+00:00',
            ),
          ],
          cursor: 'c1',
        ),
        'c1': _cuerpo(
          ordenes: [
            // Actualiza la orden 1 (mismo id, `updated_at` más nuevo,
            // `estado` distinto) y agrega la orden 2, nueva.
            _ordenJson(
              id: 1,
              estado: 'ejecutada',
              updatedAt: '2026-08-26T15:00:00+00:00',
            ),
            _ordenJson(
              id: 2,
              estado: 'vigente',
              updatedAt: '2026-08-26T15:00:00+00:00',
            ),
          ],
          cursor: 'c2',
        ),
      });
      final repositorio = CatalogoRepository(
        db: db,
        apiClient: _clienteContra(servidor),
      );

      await repositorio.pull();
      await repositorio.pull();

      final ordenes = await (db.select(
        db.ordenCatalogo,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      expect(ordenes, hasLength(2));
      expect(ordenes[0].id, 1);
      expect(ordenes[0].estado, 'ejecutada');
      expect(ordenes[1].id, 2);
      expect(ordenes[1].estado, 'vigente');

      expect(await _cursorGuardado(db), 'c2');
    });
  });
}
