import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import '../db/database.dart';

/// Pull de catálogo con cursor (`GET /api/sync/catalogo`, TE-06) — la mitad
/// de solo lectura del motor de sync. A diferencia de [SyncEngine] (push del
/// outbox), acá no hay filas locales que confirmar/rechazar una por una: el
/// servidor es la única fuente de verdad de órdenes/lotes/personas, y este
/// repositorio solo espeja lo que llega.
///
/// Sin `Stream` de estado propio ni temporizador: [pull] corre una sola vez
/// por llamada, disparado por conectividad o apertura de app (TE-19,
/// `DisparadorSync`) — mismo criterio que `SyncEngine.sincronizar()`. Cada
/// llamada trae una sola página por sección (200 filas, límite del
/// servidor); quien agota el catálogo lo invoca en loop mientras [pull]
/// devuelva `true`.
class CatalogoRepository {
  CatalogoRepository({required AppDatabase db, required ApiClient apiClient})
    : _db = db,
      _apiClient = apiClient;

  final AppDatabase _db;
  final ApiClient _apiClient;

  /// Trae el catálogo incremental desde el último cursor guardado y lo
  /// aplica local. Nunca espera nada de vuelta: quien dispara el pull solo
  /// le importa que haya terminado, no una confirmación por fila (a
  /// diferencia del outbox, acá no hay nada que "reintentar" fila por fila).
  ///
  /// Devuelve `true` cuando ordenes/lotes/personas trajeron alguna fila —
  /// señal de que esta página pudo haber tocado el límite del servidor (200
  /// filas por sección, ver `ObtenerCatalogoDesdeCursor` del lado servidor)
  /// y quede más por traer con el cursor ya avanzado — y `false` cuando el
  /// catálogo quedó al día (las tres vinieron vacías) o cuando no hubo señal
  /// de red. Quien invoque `pull()` para agotar el catálogo repite mientras
  /// devuelva `true`.
  Future<bool> pull() async {
    final cursorActual = await _leerCursor();

    final respuesta = await _pedirCatalogo(cursorActual);
    if (respuesta == null) {
      // ApiExcepcionRed: sin señal ahora, no es un error (ver
      // api_excepcion.dart). Ni el catálogo ni el cursor se tocan — el
      // próximo trigger externo vuelve a pedir desde el mismo cursor.
      return false;
    }

    // ApiExcepcionServidor/ApiExcepcionDesconocida se dejan propagar a
    // propósito (no se capturan acá): a diferencia del push, que sigue
    // avanzando fila por fila aunque el lote falle, un pull sin respuesta
    // parseable no tiene nada parcial y correcto para aplicar. Este
    // repositorio tampoco tiene un stream de estado propio (invariante:
    // "no agregues polling ni temporizador") para absorberlas como hace
    // `SyncEngine` con su `EstadoMotorSync.error` — de esas dos excepciones
    // se entera quien invoque `pull()`.
    final cuerpo = respuesta.data as Map<String, dynamic>;
    final ordenes = (cuerpo['ordenes'] as List).cast<Map<String, dynamic>>();
    final lotes = (cuerpo['lotes'] as List).cast<Map<String, dynamic>>();
    final personas = (cuerpo['personas'] as List).cast<Map<String, dynamic>>();
    final cursorNuevo = cuerpo['cursor'] as String;

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.ordenCatalogo,
          ordenes.map(_ordenDesdeJson).toList(),
        );
        batch.insertAllOnConflictUpdate(
          _db.loteCatalogo,
          lotes.map(_loteDesdeJson).toList(),
        );
        batch.insertAllOnConflictUpdate(
          _db.personaCatalogo,
          personas.map(_personaDesdeJson).toList(),
        );
      });

      // Recién acá, con el upsert de las tres tablas ya aplicado dentro de
      // la misma transacción: si algo de arriba lanza, todo hace rollback
      // (cursor viejo incluido) y el próximo pull retoma desde donde estaba
      // — nunca se avanza el cursor sin el upsert completo.
      await _db
          .into(_db.cursorCatalogo)
          .insertOnConflictUpdate(
            CursorCatalogoCompanion(
              id: const Value(0),
              cursor: Value(cursorNuevo),
            ),
          );
    });

    return ordenes.isNotEmpty || lotes.isNotEmpty || personas.isNotEmpty;
  }

  Future<Response<dynamic>?> _pedirCatalogo(String? cursor) async {
    try {
      return await _apiClient.get(
        '/api/sync/catalogo',
        query: cursor != null ? {'desde': cursor} : null,
      );
    } on ApiExcepcionRed {
      return null;
    }
  }

  Future<String?> _leerCursor() async {
    final fila = await (_db.select(
      _db.cursorCatalogo,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return fila?.cursor;
  }

  OrdenCatalogoCompanion _ordenDesdeJson(Map<String, dynamic> json) {
    return OrdenCatalogoCompanion.insert(
      id: Value(json['id'] as int),
      contratoId: json['contrato_id'] as int,
      loteId: json['lote_id'] as int,
      nroAplicacion: json['nro_aplicacion'] as int,
      litrosHa: Decimal.parse(json['litros_ha'] as String),
      humedadMinPct: Value(_decimalNullable(json['humedad_min_pct'])),
      vientoMaxKmh: Value(_decimalNullable(json['viento_max_kmh'])),
      temperaturaMaxC: Value(_decimalNullable(json['temperatura_max_c'])),
      humedadMaxPct: Value(_decimalNullable(json['humedad_max_pct'])),
      velocidadMaxKmh: Value(_decimalNullable(json['velocidad_max_kmh'])),
      alturaVueloM: Value(_decimalNullable(json['altura_vuelo_m'])),
      velocidadVueloKmh: Value(_decimalNullable(json['velocidad_vuelo_kmh'])),
      anchoPasadaM: Value(_decimalNullable(json['ancho_pasada_m'])),
      observaciones: Value(json['observaciones'] as String?),
      emitidaPorContactoId: Value(json['emitida_por_contacto_id'] as int?),
      fechaEmision: json['fecha_emision'] as String,
      estado: json['estado'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  LoteCatalogoCompanion _loteDesdeJson(Map<String, dynamic> json) {
    final geometria = json['geometria'];
    return LoteCatalogoCompanion.insert(
      id: Value(json['id'] as int),
      campoId: json['campo_id'] as int,
      codigo: json['codigo'] as String,
      hectareas: Decimal.parse(json['hectareas'] as String),
      // `geometria` ya llega parseada por dio como Map/List — se vuelve a
      // serializar a texto porque la columna es texto plano a propósito
      // (nadie la deserializa todavía, ver comentario en la tabla).
      geometria: Value(geometria == null ? null : jsonEncode(geometria)),
      restricciones: Value(json['restricciones'] as String?),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  PersonaCatalogoCompanion _personaDesdeJson(Map<String, dynamic> json) {
    return PersonaCatalogoCompanion.insert(
      id: Value(json['id'] as int),
      nombre: json['nombre'] as String,
      rol: json['rol'] as String,
      baseId: Value(json['base_id'] as int?),
      activo: json['activo'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Decimal? _decimalNullable(Object? valor) =>
      valor == null ? null : Decimal.parse(valor as String);
}
