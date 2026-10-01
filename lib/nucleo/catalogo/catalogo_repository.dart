import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../api/api_excepcion.dart';
import '../db/database.dart';
import '../db/tablas/trabajo_local.dart' show EstadoTrabajoLocal;
import 'motivo_retiro.dart';

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
  /// Devuelve `true` cuando alguna sección trajo filas (ordenes, lotes,
  /// personas, trabajos, ordenes_retiradas o trabajos_retirados). Es la señal
  /// de que esta página pudo haber tocado el límite del servidor (200 filas
  /// por sección, ver `ObtenerCatalogoDesdeCursor` del lado servidor) y quede
  /// más por traer con el cursor ya avanzado. Devuelve `false` cuando el
  /// catálogo quedó al día (las seis vinieron vacías) o cuando no hubo señal
  /// de red. Quien invoque `pull()` para agotar el catálogo repite mientras
  /// devuelva `true`.
  ///
  /// **Retirados** (tarea 26, `agrocom-api` #313): se MARCAN, nunca se borran,
  /// porque son espejo del servidor y pueden volver. Una orden o un trabajo
  /// que llega en `ordenes[]`/`trabajos[]` se desmarca en el mismo upsert.
  ///
  /// **Barrido completo**: con cursor vacío el servidor no manda retirados.
  /// Un pull que arranca así abre un barrido (`CursorCatalogo.barridoEnCurso`)
  /// y cada fila que llega queda `vistoEnBarrido`. Cuando una página llega
  /// con las seis secciones vacías, el barrido terminó bien. Recién entonces
  /// se marcan con [MotivoRetiro.fueraDeAlcance] las órdenes y los trabajos
  /// que no llegaron, salvo los que tienen un `trabajo_local` abierto.
  /// - Sin señal no se toca nada: el `ApiExcepcionRed` sale antes de la
  ///   transacción.
  /// - Un error no deja nada a medias: es rollback entero.
  /// - Un barrido cortado sigue en el próximo pull, porque la marca persiste.
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
    // `trabajos` es `required` en el contrato (HU-70), pero se tolera su
    // ausencia como lista vacía: un servidor anterior a la tarea 85 de
    // `agrocom-api` no la manda, y eso no es motivo para descartar las
    // otras tres secciones de la página.
    final trabajos = ((cuerpo['trabajos'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    // `ordenes_retiradas`/`trabajos_retirados` (#313): siempre presentes en
    // el contrato, pero se tolera su ausencia como lista vacía por el mismo
    // motivo que `trabajos`: un servidor anterior no las manda.
    final ordenesRetiradas =
        ((cuerpo['ordenes_retiradas'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
    final trabajosRetirados =
        ((cuerpo['trabajos_retirados'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
    final cursorNuevo = cuerpo['cursor'] as String;

    final hayMas =
        ordenes.isNotEmpty ||
        lotes.isNotEmpty ||
        personas.isNotEmpty ||
        trabajos.isNotEmpty ||
        ordenesRetiradas.isNotEmpty ||
        trabajosRetirados.isNotEmpty;

    await _db.transaction(() async {
      // El servidor respondió a un pedido sin `desde`: empieza un barrido
      // completo. Ninguna fila está vista todavía.
      final iniciaBarrido = cursorActual == null;
      if (iniciaBarrido) {
        await _db
            .update(_db.ordenCatalogo)
            .write(const OrdenCatalogoCompanion(vistoEnBarrido: Value(false)));
        await _db
            .update(_db.trabajoCatalogo)
            .write(
              const TrabajoCatalogoCompanion(vistoEnBarrido: Value(false)),
            );
      }

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
        batch.insertAllOnConflictUpdate(
          _db.trabajoCatalogo,
          trabajos.map(_trabajoDesdeJson).toList(),
        );
      });

      // Después del upsert: el servidor nunca manda la misma fila a la vez
      // como vigente y como retirada, así que el orden no cambia el
      // resultado, pero así una página repetida siempre deja lo mismo.
      for (final retirada in ordenesRetiradas) {
        await (_db.update(
          _db.ordenCatalogo,
        )..where((t) => t.id.equals(retirada['id'] as int))).write(
          OrdenCatalogoCompanion(
            motivoRetiro: Value(retirada['estado'] as String),
            retiroActualizadoEn: Value(
              DateTime.parse(retirada['updated_at'] as String),
            ),
          ),
        );
      }
      for (final retirado in trabajosRetirados) {
        await (_db.update(
          _db.trabajoCatalogo,
        )..where((t) => t.id.equals(retirado['id'] as int))).write(
          TrabajoCatalogoCompanion(
            motivoRetiro: Value(retirado['motivo'] as String),
            retiroActualizadoEn: Value(
              DateTime.parse(retirado['updated_at'] as String),
            ),
          ),
        );
      }

      final filaCursor = await (_db.select(
        _db.cursorCatalogo,
      )..where((t) => t.id.equals(0))).getSingleOrNull();
      var barridoEnCurso =
          iniciaBarrido || (filaCursor?.barridoEnCurso ?? false);
      if (barridoEnCurso && !hayMas) {
        await _cerrarBarrido();
        barridoEnCurso = false;
      }

      // Recién acá, con el upsert de las cuatro tablas ya aplicado dentro de
      // la misma transacción: si algo de arriba lanza, todo hace rollback
      // (cursor viejo incluido) y el próximo pull retoma desde donde estaba
      // — nunca se avanza el cursor sin el upsert completo.
      await _db
          .into(_db.cursorCatalogo)
          .insertOnConflictUpdate(
            CursorCatalogoCompanion(
              id: const Value(0),
              cursor: Value(cursorNuevo),
              barridoEnCurso: Value(barridoEnCurso),
            ),
          );
    });

    return hayMas;
  }

  /// Fin de un barrido completo terminado bien: marca con
  /// [MotivoRetiro.fueraDeAlcance] lo que no llegó y no estaba ya retirado.
  /// Nunca un trabajo con `trabajo_local` abierto, ni la orden de uno: el
  /// piloto no se queda sin el trabajo en el que está volando.
  Future<void> _cerrarBarrido() async {
    final trabajosAbiertos = _db.selectOnly(_db.trabajoLocal)
      ..addColumns([_db.trabajoLocal.uuidCliente])
      ..where(_db.trabajoLocal.estado.equalsValue(EstadoTrabajoLocal.abierto));
    await (_db.update(_db.trabajoCatalogo)..where(
          (t) =>
              t.motivoRetiro.isNull() &
              (t.vistoEnBarrido.isNull() | t.vistoEnBarrido.equals(false)) &
              t.uuidCliente.isNotInQuery(trabajosAbiertos),
        ))
        .write(
          const TrabajoCatalogoCompanion(
            motivoRetiro: Value(MotivoRetiro.fueraDeAlcance),
            retiroActualizadoEn: Value(null),
          ),
        );

    final ordenesConTrabajoAbierto = _db.selectOnly(_db.trabajoLocal)
      ..addColumns([_db.trabajoLocal.ordenId])
      ..where(_db.trabajoLocal.estado.equalsValue(EstadoTrabajoLocal.abierto));
    await (_db.update(_db.ordenCatalogo)..where(
          (t) =>
              t.motivoRetiro.isNull() &
              (t.vistoEnBarrido.isNull() | t.vistoEnBarrido.equals(false)) &
              t.id.isNotInQuery(ordenesConTrabajoAbierto),
        ))
        .write(
          const OrdenCatalogoCompanion(
            motivoRetiro: Value(MotivoRetiro.fueraDeAlcance),
            retiroActualizadoEn: Value(null),
          ),
        );
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

  /// `lotes.first` como `loteId` (TE-20, HU-92 de `agrocom-api` tarea 107):
  /// una orden ya puede cubrir varios lotes, pero la UI de lista/detalle de
  /// este repo sigue asumiendo uno solo — soporte multi-lote real queda para
  /// HU-92 (lado app), planificada aparte (ver `orden_catalogo.dart`). Del
  /// resto de `lotes[]` se guardan la cantidad y la suma exacta de
  /// `hectareas_solicitadas` (TE-23), para no mostrar el primer lote como si
  /// fuera la orden entera.
  OrdenCatalogoCompanion _ordenDesdeJson(Map<String, dynamic> json) {
    final lotes = (json['lotes'] as List).cast<Map<String, dynamic>>();
    final hectareasSolicitadas = lotes.fold(
      Decimal.zero,
      (suma, lote) =>
          suma + Decimal.parse(lote['hectareas_solicitadas'] as String),
    );
    return OrdenCatalogoCompanion.insert(
      id: Value(json['id'] as int),
      contratoId: json['contrato_id'] as int,
      loteId: lotes.first['lote_id'] as int,
      cantidadLotes: Value(lotes.length),
      hectareasSolicitadas: Value(hectareasSolicitadas),
      nroAplicacion: json['nro_aplicacion'] as int,
      litrosHa: Value(_decimalNullable(json['litros_ha'])),
      kilosPorVuelo: Value(_decimalNullable(json['kilos_por_vuelo'])),
      observaciones: Value(json['observaciones'] as String?),
      // Llegó en `ordenes[]`: vigente para el servidor. Se desmarca si
      // estaba retirada (una `pausada` que vuelve a `vigente`).
      motivoRetiro: const Value(null),
      retiroActualizadoEn: const Value(null),
      vistoEnBarrido: const Value(true),
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
      propiedadId: json['propiedad_id'] as int,
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

  /// Trabajo asignado desde el panel (HU-70). `uuid_cliente` se guarda TAL
  /// CUAL lo generó el panel — la app nunca genera uno propio para este
  /// trabajo (invariante 2 aplicada a un registro de origen servidor).
  ///
  /// Los siete límites climáticos y parámetros de vuelo (tarea 23) viajan
  /// EFECTIVOS desde `agrocom-api` #309 (`LimitesEfectivos`):
  /// `viento_max_kmh`, `temperatura_max_c` y `humedad_max_pct` siempre traen
  /// valor (el de la Orden de Trabajo o el default del sistema); los otros
  /// cuatro llegan `null` si la Orden de Trabajo no los fija. El parseo
  /// tolera `null` en los siete igual: las columnas son nullable y un
  /// servidor anterior a #309 los mandaba así. Siempre `Decimal`
  /// (invariante 9 de CLAUDE.md).
  TrabajoCatalogoCompanion _trabajoDesdeJson(Map<String, dynamic> json) {
    return TrabajoCatalogoCompanion.insert(
      id: Value(json['id'] as int),
      uuidCliente: json['uuid_cliente'] as String,
      ordenId: json['orden_id'] as int,
      loteId: json['lote_id'] as int,
      hectareasDeclaradas: Decimal.parse(
        json['hectareas_declaradas'] as String,
      ),
      equipoTrabajoId: json['equipo_trabajo_id'] as int,
      humedadMinPct: Value(_decimalNullable(json['humedad_min_pct'])),
      vientoMaxKmh: Value(_decimalNullable(json['viento_max_kmh'])),
      temperaturaMaxC: Value(_decimalNullable(json['temperatura_max_c'])),
      humedadMaxPct: Value(_decimalNullable(json['humedad_max_pct'])),
      alturaVueloM: Value(_decimalNullable(json['altura_vuelo_m'])),
      velocidadVueloKmh: Value(_decimalNullable(json['velocidad_vuelo_kmh'])),
      anchoPasadaM: Value(_decimalNullable(json['ancho_pasada_m'])),
      // Llegó en `trabajos[]`: asignado para el servidor. Se desmarca si
      // estaba retirado.
      motivoRetiro: const Value(null),
      retiroActualizadoEn: const Value(null),
      vistoEnBarrido: const Value(true),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Decimal? _decimalNullable(Object? valor) =>
      valor == null ? null : Decimal.parse(valor as String);
}
