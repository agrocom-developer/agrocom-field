// Etapa 2 de TE-06: pull de catálogo con cursor, repositorio contra un
// `ApiClient` mockeado (mismo patrón que `test/nucleo/sync/sync_engine_test.dart`).

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/catalogo/catalogo_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiClientFalso extends Mock implements ApiClient {}

Map<String, dynamic> _ordenJson({
  int id = 1,
  int loteId = 3,
  String estado = 'vigente',
  String updatedAt = '2026-08-26T12:00:00+00:00',
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
  'emitida_por_contacto_id': 2,
  'fecha_emision': '2026-08-26',
  'estado': estado,
  'updated_at': updatedAt,
};

Map<String, dynamic> _loteJson({
  int id = 3,
  Object? geometria,
  String updatedAt = '2026-08-26T12:00:00+00:00',
}) => {
  'id': id,
  'propiedad_id': 1,
  'codigo': 'L-01',
  'hectareas': '120.50',
  'geometria': geometria,
  'restricciones': null,
  'updated_at': updatedAt,
};

Map<String, dynamic> _personaJson({
  int id = 5,
  String updatedAt = '2026-08-26T12:00:00+00:00',
}) => {
  'id': id,
  'nombre': 'Piloto Uno',
  'rol': 'piloto',
  'base_id': 1,
  'activo': true,
  'updated_at': updatedAt,
};

Response<dynamic> _respuestaCatalogo({
  List<Map<String, dynamic>> ordenes = const [],
  List<Map<String, dynamic>> lotes = const [],
  List<Map<String, dynamic>> personas = const [],
  List<Map<String, dynamic>>? trabajos,
  List<Map<String, dynamic>>? ordenesRetiradas,
  List<Map<String, dynamic>>? trabajosRetirados,
  required String cursor,
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/sync/catalogo'),
    statusCode: 200,
    data: {
      'ordenes': ordenes,
      'lotes': lotes,
      'personas': personas,
      'trabajos': ?trabajos,
      'ordenes_retiradas': ?ordenesRetiradas,
      'trabajos_retirados': ?trabajosRetirados,
      'cursor': cursor,
    },
  );
}

void main() {
  late AppDatabase db;
  late _ApiClientFalso apiClient;
  late CatalogoRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    apiClient = _ApiClientFalso();
    repositorio = CatalogoRepository(db: db, apiClient: apiClient);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String?> cursorGuardado() async {
    final fila = await (db.select(
      db.cursorCatalogo,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return fila?.cursor;
  }

  test('primera sincronización (sin cursor previo) trae ordenes/lotes/personas '
      'y persiste el cursor devuelto', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        ordenes: [_ordenJson()],
        lotes: [_loteJson()],
        personas: [_personaJson()],
        cursor: 'cursor-1',
      ),
    );

    await repositorio.pull();

    verify(() => apiClient.get('/api/sync/catalogo', query: null)).called(1);

    final ordenes = await db.select(db.ordenCatalogo).get();
    expect(ordenes, hasLength(1));
    expect(ordenes.single.litrosHa, Decimal.parse('10.00'));

    final lotes = await db.select(db.loteCatalogo).get();
    expect(lotes, hasLength(1));

    final personas = await db.select(db.personaCatalogo).get();
    expect(personas, hasLength(1));

    expect(await cursorGuardado(), 'cursor-1');
  });

  test('TE-20: una orden con insumo sólido (litros_ha null, kilos_por_vuelo '
      'con valor) se guarda sin tirar excepción, y loteId toma el primer '
      'lote de `lotes[]` (HU-92 de agrocom-api reemplazó el `lote_id` único '
      'por un arreglo)', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        ordenes: [
          {
            ..._ordenJson(id: 9, loteId: 3),
            'lotes': [
              {'lote_id': 3, 'hectareas_solicitadas': '50.00'},
              {'lote_id': 4, 'hectareas_solicitadas': '20.00'},
            ],
            'litros_ha': null,
            'kilos_por_vuelo': '8.50',
          },
        ],
        lotes: const [],
        personas: const [],
        cursor: 'cursor-solido',
      ),
    );

    await repositorio.pull();

    final orden = (await db.select(db.ordenCatalogo).get()).single;
    expect(orden.loteId, 3, reason: 'toma el primer lote del arreglo');
    expect(orden.litrosHa, isNull);
    expect(orden.kilosPorVuelo, Decimal.parse('8.50'));
  });

  test('TE-23: guarda cuántos lotes cubre la orden y la suma exacta de '
      '`lotes[].hectareas_solicitadas` (ADR 0022 de agrocom-api)', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        ordenes: [
          {
            ..._ordenJson(id: 9, loteId: 3),
            'lotes': [
              {'lote_id': 3, 'hectareas_solicitadas': '50.10'},
              {'lote_id': 4, 'hectareas_solicitadas': '20.20'},
              {'lote_id': 5, 'hectareas_solicitadas': '0.70'},
            ],
          },
          _ordenJson(id: 10, loteId: 6),
        ],
        cursor: 'cursor-lotes',
      ),
    );

    await repositorio.pull();

    final ordenes = await (db.select(
      db.ordenCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(ordenes[0].loteId, 3);
    expect(ordenes[0].cantidadLotes, 3);
    // 50.10 + 20.20 + 0.70 en decimal exacto (en double daría 71.00000…01).
    expect(ordenes[0].hectareasSolicitadas, Decimal.parse('71.00'));
    expect(ordenes[1].cantidadLotes, 1);
    expect(ordenes[1].hectareasSolicitadas, Decimal.parse('50.00'));
  });

  test(
    'ApiExcepcionRed no toca ni el cursor ni las tablas de catálogo',
    () async {
      when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => _respuestaCatalogo(
          ordenes: [_ordenJson()],
          cursor: 'cursor-previo',
        ),
      );
      await repositorio.pull();
      expect(await cursorGuardado(), 'cursor-previo');

      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenThrow(const ApiExcepcionRed());
      await repositorio.pull();

      expect(await cursorGuardado(), 'cursor-previo');
      expect(await db.select(db.ordenCatalogo).get(), hasLength(1));
    },
  );

  test(
    'un pull posterior a uno exitoso manda el cursor guardado como `desde`',
    () async {
      when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => _respuestaCatalogo(cursor: 'el-cursor-guardado'),
      );
      await repositorio.pull();

      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenAnswer((_) async => _respuestaCatalogo(cursor: 'cursor-2'));
      await repositorio.pull();

      verify(
        () => apiClient.get(
          '/api/sync/catalogo',
          query: {'desde': 'el-cursor-guardado'},
        ),
      ).called(1);
    },
  );

  test('geometria null se guarda como null', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async =>
          _respuestaCatalogo(lotes: [_loteJson(geometria: null)], cursor: 'c1'),
    );

    await repositorio.pull();

    final lote = (await db.select(db.loteCatalogo).get()).single;
    expect(lote.geometria, isNull);
  });

  test('geometria con objeto se serializa a JSON de texto plano', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        lotes: [
          _loteJson(
            geometria: {
              'type': 'Polygon',
              'coordinates': [
                [
                  [1, 2],
                  [3, 4],
                ],
              ],
            },
          ),
        ],
        cursor: 'c1',
      ),
    );

    await repositorio.pull();

    final lote = (await db.select(db.loteCatalogo).get()).single;
    expect(lote.geometria, '{"type":"Polygon","coordinates":[[[1,2],[3,4]]]}');
  });

  test('pull() devuelve false cuando ordenes/lotes/personas vienen vacías '
      '(catálogo al día)', () async {
    when(
      () => apiClient.get(any(), query: any(named: 'query')),
    ).thenAnswer((_) async => _respuestaCatalogo(cursor: 'c1'));

    expect(await repositorio.pull(), isFalse);
  });

  test('HU-70: upsertea trabajos[] con el uuid_cliente del panel tal cual y '
      'hectáreas en decimal exacto', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        trabajos: [
          {
            'id': 42,
            'uuid_cliente': '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a',
            'orden_id': 1,
            'lote_id': 3,
            'hectareas_declaradas': '300.10',
            'equipo_trabajo_id': 7,
            'updated_at': '2026-09-22T12:00:00+00:00',
          },
        ],
        cursor: 'c-trabajos',
      ),
    );

    await repositorio.pull();

    final trabajo = (await db.select(db.trabajoCatalogo).get()).single;
    expect(trabajo.id, 42);
    expect(trabajo.uuidCliente, '9a1b7e3e-2f7a-4b3d-8c1e-6f2a1d9c4b0a');
    expect(trabajo.ordenId, 1);
    expect(trabajo.loteId, 3);
    expect(trabajo.hectareasDeclaradas, Decimal.parse('300.10'));
    expect(trabajo.equipoTrabajoId, 7);
    expect(await cursorGuardado(), 'c-trabajos');
  });

  test('tarea 23: guarda los límites climáticos y de vuelo de trabajos[] en '
      'decimal exacto, y en null cuando el panel no los completó', () async {
    Map<String, dynamic> trabajoJson({
      required int id,
      required String? valor,
      String updatedAt = '2026-09-22T12:00:00+00:00',
    }) => {
      'id': id,
      'uuid_cliente': 'uuid-panel-$id',
      'orden_id': 1,
      'lote_id': 3,
      'hectareas_declaradas': '300.00',
      'equipo_trabajo_id': 7,
      'humedad_min_pct': valor,
      'viento_max_kmh': valor,
      'temperatura_max_c': valor,
      'humedad_max_pct': valor,
      'altura_vuelo_m': valor,
      'velocidad_vuelo_kmh': valor,
      'ancho_pasada_m': valor,
      'updated_at': updatedAt,
    };

    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        trabajos: [
          trabajoJson(id: 42, valor: '17.25'),
          trabajoJson(id: 43, valor: null),
        ],
        cursor: 'c1',
      ),
    );
    await repositorio.pull();

    final trabajos = await (db.select(
      db.trabajoCatalogo,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final conLimites = trabajos[0];
    expect(conLimites.humedadMinPct, Decimal.parse('17.25'));
    expect(conLimites.vientoMaxKmh, Decimal.parse('17.25'));
    expect(conLimites.temperaturaMaxC, Decimal.parse('17.25'));
    expect(conLimites.humedadMaxPct, Decimal.parse('17.25'));
    expect(conLimites.alturaVueloM, Decimal.parse('17.25'));
    expect(conLimites.velocidadVueloKmh, Decimal.parse('17.25'));
    expect(conLimites.anchoPasadaM, Decimal.parse('17.25'));
    final sinLimites = trabajos[1];
    expect(sinLimites.humedadMinPct, isNull);
    expect(sinLimites.vientoMaxKmh, isNull);
    expect(sinLimites.temperaturaMaxC, isNull);
    expect(sinLimites.humedadMaxPct, isNull);
    expect(sinLimites.alturaVueloM, isNull);
    expect(sinLimites.velocidadVueloKmh, isNull);
    expect(sinLimites.anchoPasadaM, isNull);

    // Un pull posterior que trae el trabajo sin límites ya completados los
    // actualiza sobre la misma fila.
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        trabajos: [
          trabajoJson(
            id: 43,
            valor: '8.00',
            updatedAt: '2026-09-23T12:00:00+00:00',
          ),
        ],
        cursor: 'c2',
      ),
    );
    await repositorio.pull();

    final actualizado = await (db.select(
      db.trabajoCatalogo,
    )..where((t) => t.id.equals(43))).getSingle();
    expect(actualizado.vientoMaxKmh, Decimal.parse('8.00'));
    expect(actualizado.anchoPasadaM, Decimal.parse('8.00'));
  });

  test('HU-70: pull() devuelve true cuando solo trabajos trajo filas (cuenta '
      'para el "hay más" del loop de catálogo)', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(
        trabajos: [
          {
            'id': 42,
            'uuid_cliente': 'uuid-panel-42',
            'orden_id': 1,
            'lote_id': 3,
            'hectareas_declaradas': '300.00',
            'equipo_trabajo_id': 7,
            'updated_at': '2026-09-22T12:00:00+00:00',
          },
        ],
        cursor: 'c1',
      ),
    );

    expect(await repositorio.pull(), isTrue);
  });

  test('HU-70: pull() devuelve false con las cuatro secciones vacías, '
      'trabajos incluido', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(trabajos: const [], cursor: 'c1'),
    );

    expect(await repositorio.pull(), isFalse);
  });

  test('pull() devuelve true cuando alguna sección trajo filas', () async {
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => _respuestaCatalogo(personas: [_personaJson()], cursor: 'c1'),
    );

    expect(await repositorio.pull(), isTrue);
  });

  test('pull() devuelve false ante ApiExcepcionRed (sin señal)', () async {
    when(
      () => apiClient.get(any(), query: any(named: 'query')),
    ).thenThrow(const ApiExcepcionRed());

    expect(await repositorio.pull(), isFalse);
  });

  test('llamado en loop mientras pull() devuelva true, agota el catálogo '
      'página por página y para en la primera página vacía', () async {
    var llamados = 0;
    when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer((
      _,
    ) async {
      llamados++;
      return switch (llamados) {
        1 => _respuestaCatalogo(
          ordenes: [_ordenJson(id: 1)],
          cursor: 'cursor-1',
        ),
        2 => _respuestaCatalogo(
          ordenes: [_ordenJson(id: 2)],
          cursor: 'cursor-2',
        ),
        _ => _respuestaCatalogo(cursor: 'cursor-2'),
      };
    });

    var hayMas = true;
    var iteraciones = 0;
    while (hayMas) {
      hayMas = await repositorio.pull();
      iteraciones++;
    }

    expect(iteraciones, 3);
    expect(llamados, 3);
    expect(await db.select(db.ordenCatalogo).get(), hasLength(2));
    expect(await cursorGuardado(), 'cursor-2');

    verify(() => apiClient.get('/api/sync/catalogo', query: null)).called(1);
    verify(
      () => apiClient.get('/api/sync/catalogo', query: {'desde': 'cursor-1'}),
    ).called(1);
    verify(
      () => apiClient.get('/api/sync/catalogo', query: {'desde': 'cursor-2'}),
    ).called(1);
  });

  group('tarea 26: retirados (agrocom-api #313) y barrido completo', () {
    Map<String, dynamic> trabajoJson({
      required int id,
      int ordenId = 1,
      String updatedAt = '2026-09-22T12:00:00+00:00',
    }) => {
      'id': id,
      'uuid_cliente': 'uuid-panel-$id',
      'orden_id': ordenId,
      'lote_id': 3,
      'hectareas_declaradas': '300.00',
      'equipo_trabajo_id': 7,
      'humedad_min_pct': null,
      'viento_max_kmh': '17.00',
      'temperatura_max_c': '30.00',
      'humedad_max_pct': '90.00',
      'altura_vuelo_m': null,
      'velocidad_vuelo_kmh': null,
      'ancho_pasada_m': null,
      'updated_at': updatedAt,
    };

    /// Responde por `desde`, como el servidor real: cada página depende del
    /// cursor que reenvía el cliente. Un valor `Exception` se lanza.
    void servidor(Map<String?, Object> paginas) {
      when(() => apiClient.get(any(), query: any(named: 'query'))).thenAnswer((
        invocacion,
      ) async {
        final query =
            invocacion.namedArguments[#query] as Map<String, dynamic>?;
        final pagina = paginas[query?['desde'] as String?];
        if (pagina is Exception) throw pagina;
        return pagina! as Response<dynamic>;
      });
    }

    Future<void> fijarCursor(String cursor) => db
        .into(db.cursorCatalogo)
        .insertOnConflictUpdate(
          CursorCatalogoCompanion(id: const Value(0), cursor: Value(cursor)),
        );

    Future<OrdenCatalogoData> orden(int id) => (db.select(
      db.ordenCatalogo,
    )..where((t) => t.id.equals(id))).getSingle();

    Future<TrabajoCatalogoData> trabajo(int id) => (db.select(
      db.trabajoCatalogo,
    )..where((t) => t.id.equals(id))).getSingle();

    test('ordenes_retiradas marca la orden sin borrarla, y si vuelve en '
        'ordenes[] se desmarca (vigente → pausada → vigente)', () async {
      servidor({
        null: _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'c1'),
        'c1': _respuestaCatalogo(
          ordenesRetiradas: [
            {
              'id': 1,
              'estado': 'pausada',
              'updated_at': '2026-09-25T12:00:00+00:00',
            },
          ],
          cursor: 'c2',
        ),
        'c2': _respuestaCatalogo(
          ordenes: [_ordenJson(id: 1, updatedAt: '2026-09-26T12:00:00+00:00')],
          cursor: 'c3',
        ),
      });

      await repositorio.pull();
      await repositorio.pull();
      final pausada = await orden(1);
      expect(pausada.motivoRetiro, 'pausada');
      expect(
        pausada.retiroActualizadoEn!.isAtSameMomentAs(
          DateTime.utc(2026, 9, 25, 12),
        ),
        isTrue,
      );
      expect(await db.select(db.ordenCatalogo).get(), hasLength(1));

      await repositorio.pull();
      final reanudada = await orden(1);
      expect(reanudada.motivoRetiro, isNull);
      expect(reanudada.retiroActualizadoEn, isNull);
    });

    test(
      'trabajos_retirados marca el trabajo con su motivo, sin borrarlo',
      () async {
        servidor({
          null: _respuestaCatalogo(
            trabajos: [trabajoJson(id: 42)],
            cursor: 'c1',
          ),
          'c1': _respuestaCatalogo(
            trabajosRetirados: [
              {
                'id': 42,
                'uuid_cliente': 'uuid-panel-42',
                'motivo': 'reasignado',
                'updated_at': '2026-09-25T12:00:00+00:00',
              },
            ],
            cursor: 'c2',
          ),
        });

        await repositorio.pull();
        expect(await repositorio.pull(), isTrue);

        final retirado = await trabajo(42);
        expect(retirado.motivoRetiro, 'reasignado');
        expect(retirado.uuidCliente, 'uuid-panel-42');
        expect(await cursorGuardado(), 'c2');
      },
    );

    test(
      'un retirado que el dispositivo no tiene no crea ninguna fila',
      () async {
        await fijarCursor('c1');
        servidor({
          'c1': _respuestaCatalogo(
            ordenesRetiradas: [
              {
                'id': 9,
                'estado': 'cancelada',
                'updated_at': '2026-09-25T12:00:00+00:00',
              },
            ],
            trabajosRetirados: [
              {
                'id': 99,
                'uuid_cliente': 'uuid-panel-99',
                'motivo': 'dado_de_baja',
                'updated_at': '2026-09-25T12:00:00+00:00',
              },
            ],
            cursor: 'c2',
          ),
        });

        expect(await repositorio.pull(), isTrue);
        expect(await db.select(db.ordenCatalogo).get(), isEmpty);
        expect(await db.select(db.trabajoCatalogo).get(), isEmpty);
      },
    );

    test('sin las claves de retirados (servidor anterior a #313) aplica el '
        'resto de la página', () async {
      servidor({
        null: _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'c1'),
      });

      expect(await repositorio.pull(), isTrue);
      expect((await orden(1)).motivoRetiro, isNull);
    });

    test('barrido completo: marca fuera_de_alcance lo que no llegó, nunca un '
        'trabajo con trabajo_local abierto ni su orden', () async {
      // Estado previo a v14: órdenes 1-3 y trabajos 41 (otro equipo), 42 y
      // 43 (abierto en este dispositivo), con el cursor ya reseteado.
      servidor({
        null: _respuestaCatalogo(
          ordenes: [_ordenJson(id: 1), _ordenJson(id: 2), _ordenJson(id: 3)],
          trabajos: [
            trabajoJson(id: 41),
            trabajoJson(id: 42),
            trabajoJson(id: 43, ordenId: 3),
          ],
          cursor: 'c-viejo',
        ),
      });
      await repositorio.pull();
      await db
          .into(db.trabajoLocal)
          .insert(
            TrabajoLocalCompanion.insert(
              uuidCliente: 'uuid-panel-43',
              ordenId: 3,
              loteId: 3,
              nroAplicacion: 1,
              inicio: DateTime.utc(2026, 9, 23, 8),
            ),
          );
      await db.delete(db.cursorCatalogo).go();

      // Barrido: solo llegan la orden 1 y el trabajo 42, en dos páginas.
      servidor({
        null: _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'b1'),
        'b1': _respuestaCatalogo(trabajos: [trabajoJson(id: 42)], cursor: 'b2'),
        'b2': _respuestaCatalogo(cursor: 'b2'),
      });
      expect(await repositorio.pull(), isTrue);
      expect(await repositorio.pull(), isTrue);
      // A mitad del barrido todavía no se marcó nada.
      expect((await trabajo(41)).motivoRetiro, isNull);
      expect((await orden(2)).motivoRetiro, isNull);

      expect(await repositorio.pull(), isFalse);

      expect((await orden(1)).motivoRetiro, isNull);
      expect((await orden(2)).motivoRetiro, 'fuera_de_alcance');
      expect((await orden(2)).retiroActualizadoEn, isNull);
      expect((await orden(3)).motivoRetiro, isNull, reason: 'trabajo abierto');
      expect((await trabajo(41)).motivoRetiro, 'fuera_de_alcance');
      expect((await trabajo(42)).motivoRetiro, isNull);
      expect((await trabajo(43)).motivoRetiro, isNull, reason: 'abierto');
      expect(await db.select(db.trabajoCatalogo).get(), hasLength(3));
      expect(
        (await db.select(db.cursorCatalogo).getSingle()).barridoEnCurso,
        isFalse,
      );
    });

    test('barrido cortado sin señal no marca nada; sigue en el próximo pull '
        'y limpia recién al terminar', () async {
      servidor({
        null: _respuestaCatalogo(
          ordenes: [_ordenJson(id: 1), _ordenJson(id: 2)],
          cursor: 'c-viejo',
        ),
      });
      await repositorio.pull();
      await db.delete(db.cursorCatalogo).go();

      servidor({
        null: _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'b1'),
        'b1': const ApiExcepcionRed(),
      });
      await repositorio.pull();
      expect(await repositorio.pull(), isFalse);
      expect((await orden(2)).motivoRetiro, isNull);
      expect(
        (await db.select(db.cursorCatalogo).getSingle()).barridoEnCurso,
        isTrue,
      );

      servidor({'b1': _respuestaCatalogo(cursor: 'b1')});
      expect(await repositorio.pull(), isFalse);
      expect((await orden(2)).motivoRetiro, 'fuera_de_alcance');
      expect((await orden(1)).motivoRetiro, isNull);
    });

    test('un error del servidor a mitad del barrido no marca nada', () async {
      servidor({
        null: _respuestaCatalogo(
          ordenes: [_ordenJson(id: 1), _ordenJson(id: 2)],
          cursor: 'c-viejo',
        ),
      });
      await repositorio.pull();
      await db.delete(db.cursorCatalogo).go();

      servidor({
        null: _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'b1'),
        'b1': const ApiExcepcionServidor(500, null),
      });
      await repositorio.pull();
      await expectLater(
        repositorio.pull(),
        throwsA(isA<ApiExcepcionServidor>()),
      );

      expect((await orden(2)).motivoRetiro, isNull);
      expect(await cursorGuardado(), 'b1');
    });

    test(
      'sin conexión en el primer pull del barrido no se toca nada',
      () async {
        servidor({
          null: _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'c1'),
        });
        await repositorio.pull();
        await db.delete(db.cursorCatalogo).go();

        servidor({null: const ApiExcepcionRed()});
        expect(await repositorio.pull(), isFalse);

        expect((await orden(1)).motivoRetiro, isNull);
        expect(await cursorGuardado(), isNull);
      },
    );

    test('fuera de un barrido, una página vacía no marca nada', () async {
      servidor({
        null: _respuestaCatalogo(
          ordenes: [_ordenJson(id: 1), _ordenJson(id: 2)],
          cursor: 'c1',
        ),
        'c1': _respuestaCatalogo(ordenes: [_ordenJson(id: 1)], cursor: 'c2'),
        'c2': _respuestaCatalogo(cursor: 'c2'),
      });
      // El primer pull es un barrido (cursor vacío) que trae las dos; el
      // segundo lo cierra sin marcar nada porque las dos llegaron.
      await repositorio.pull();
      await repositorio.pull();
      await repositorio.pull();

      expect((await orden(2)).motivoRetiro, isNull);
    });
  });
}
