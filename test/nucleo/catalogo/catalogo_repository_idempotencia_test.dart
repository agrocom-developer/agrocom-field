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
  'lotes': [
    {'lote_id': loteId, 'hectareas_solicitadas': '50.00'},
  ],
  'nro_aplicacion': 1,
  'litros_ha': '10.00',
  'kilos_por_vuelo': null,
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
  List<Map<String, dynamic>>? trabajos,
  required String cursor,
}) => {
  'ordenes': ordenes,
  'lotes': lotes,
  'personas': personas,
  'trabajos': ?trabajos,
  'cursor': cursor,
};

/// `TrabajoCatalogo` del `openapi.yaml` (HU-70).
Map<String, dynamic> _trabajoJson({
  required int id,
  required String uuidCliente,
  String hectareas = '300.00',
  String updatedAt = '2026-09-22T12:00:00+00:00',
}) => {
  'id': id,
  'uuid_cliente': uuidCliente,
  'orden_id': 1,
  'lote_id': 3,
  'hectareas_declaradas': hectareas,
  'equipo_trabajo_id': 7,
  'updated_at': updatedAt,
};

/// Volcado completo y ordenado de las tablas de catálogo — "la base
/// idéntica" de la invariante 10 se compara con esto.
Future<List<Object>> _volcado(AppDatabase db) async => [
  ...await (db.select(
    db.ordenCatalogo,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
  ...await (db.select(
    db.trabajoCatalogo,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
  ...await db.select(db.cursorCatalogo).get(),
];

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

    test(
      'HU-70: la misma página con trabajos aplicada diez veces deja la '
      'base idéntica, sin duplicar trabajos ni cambiar su uuid_cliente',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final pagina = _cuerpo(
          ordenes: [
            _ordenJson(
              id: 1,
              estado: 'vigente',
              updatedAt: '2026-09-20T12:00:00+00:00',
            ),
          ],
          trabajos: [
            _trabajoJson(id: 42, uuidCliente: 'uuid-panel-42'),
            _trabajoJson(
              id: 43,
              uuidCliente: 'uuid-panel-43',
              hectareas: '0.10',
            ),
          ],
          cursor: 'c1',
        );
        final servidor = _ServidorCatalogoFalso({null: pagina, 'c1': pagina});
        final repositorio = CatalogoRepository(
          db: db,
          apiClient: _clienteContra(servidor),
        );

        await repositorio.pull();
        final despuesDeUno = await _volcado(db);
        for (var i = 0; i < 9; i++) {
          await repositorio.pull();
        }

        expect(await _volcado(db), despuesDeUno);
        final trabajos = await (db.select(
          db.trabajoCatalogo,
        )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
        expect(trabajos.map((t) => t.uuidCliente), [
          'uuid-panel-42',
          'uuid-panel-43',
        ]);
      },
    );

    // El cursor solo avanza, así que el único "desorden" posible en el pull
    // es repetir una página ya aplicada (reintento tras una respuesta
    // perdida). Reaplicar una página ANTERIOR sí volvería atrás un trabajo
    // actualizado — mismo comportamiento que órdenes/lotes/personas
    // (last-write-wins por upsert), que el cursor monótono impide.
    test(
      'HU-70: páginas con trabajos repetidas por reintento convergen al '
      'mismo estado que sin reintentos, con la actualización aplicada',
      () async {
        final viejo = _trabajoJson(id: 42, uuidCliente: 'uuid-panel-42');
        final nuevo = _trabajoJson(
          id: 42,
          uuidCliente: 'uuid-panel-42',
          hectareas: '250.00',
          updatedAt: '2026-09-23T12:00:00+00:00',
        );
        final otro = _trabajoJson(id: 44, uuidCliente: 'uuid-panel-44');

        Future<List<Object>> aplicar(List<String?> desdes) async {
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
          final servidor = _ServidorCatalogoFalso({
            null: _cuerpo(trabajos: [viejo], cursor: 'c1'),
            'c1': _cuerpo(trabajos: [nuevo, otro], cursor: 'c2'),
            'c2': _cuerpo(trabajos: const [], cursor: 'c2'),
          });
          final cliente = _clienteContra(servidor);
          for (final desde in desdes) {
            // Fija el cursor guardado antes de cada pull para reproducir el
            // orden de páginas pedido, como lo haría un reintento.
            await (db.delete(db.cursorCatalogo)).go();
            if (desde != null) {
              await db
                  .into(db.cursorCatalogo)
                  .insert(
                    CursorCatalogoCompanion.insert(
                      id: const Value(0),
                      cursor: Value(desde),
                    ),
                  );
            }
            await CatalogoRepository(db: db, apiClient: cliente).pull();
          }
          return [
            ...await (db.select(
              db.trabajoCatalogo,
            )..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
          ];
        }

        final enOrden = await aplicar([null, 'c1', 'c2']);
        final repetidoEnOrden = await aplicar([null, 'c1', 'c1', 'c2', 'c2']);

        expect(repetidoEnOrden, enOrden);
        expect(enOrden, hasLength(2));
        expect(
          (enOrden.first as TrabajoCatalogoData).hectareasDeclaradas.toString(),
          '250',
        );
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
