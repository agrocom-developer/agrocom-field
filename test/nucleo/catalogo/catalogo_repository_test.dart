// Etapa 2 de TE-06: pull de catálogo con cursor, repositorio contra un
// `ApiClient` mockeado (mismo patrón que `test/nucleo/sync/sync_engine_test.dart`).

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/catalogo/catalogo_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
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
  'lote_id': loteId,
  'nro_aplicacion': 1,
  'litros_ha': '10.00',
  'humedad_min_pct': '60.00',
  'viento_max_kmh': '15.00',
  'temperatura_max_c': '32.00',
  'humedad_max_pct': '90.00',
  'velocidad_max_kmh': '25.00',
  'altura_vuelo_m': '3.00',
  'velocidad_vuelo_kmh': '18.00',
  'ancho_pasada_m': '7.00',
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
  'campo_id': 1,
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
  required String cursor,
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/sync/catalogo'),
    statusCode: 200,
    data: {
      'ordenes': ordenes,
      'lotes': lotes,
      'personas': personas,
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
}
