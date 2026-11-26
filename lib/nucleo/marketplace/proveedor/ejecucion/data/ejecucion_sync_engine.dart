import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../../api/api_client.dart';
import '../../../../api/api_excepcion.dart';
import '../../../../db/database.dart';
import '../../../../db/tablas/foto_ejecucion.dart';
import '../../../../db/tablas/registro_ejecucion.dart';
import '../../negociacion/data/mapeo_negociacion.dart';

/// Motor de subida de la ejecución de un servicio adjudicado (ADR 0016).
///
/// Empuja, en este orden: (1) los registros de `registro_ejecucion` uno por
/// uno, por `secuencia` ascendente (invariante 5) a los endpoints de la
/// solicitud; (2) las fotos de `foto_ejecucion`, una por request
/// (invariante 7); (3) baja el catálogo de servicios adjudicados.
///
/// Es idempotente por `uuid_cliente`: reenviar lo mismo dos, tres o diez
/// veces deja la base igual, porque el servidor responde `200` con el mismo
/// registro y acá `200` y `201` valen lo mismo (invariante 9). Un registro ya
/// `confirmado` nunca se reescribe (invariante 6). Ante un corte de red o un
/// error del servidor el ciclo se detiene sin tocar nada, para no romper el
/// orden causal; un rechazo definitivo (`403`, `404`, `409`, `422`) marca esa
/// fila `rechazado` con su motivo y el ciclo sigue con la siguiente.
class EjecucionSyncEngine {
  EjecucionSyncEngine({required ApiClient api, required AppDatabase db})
    : _api = api,
      _db = db;

  final ApiClient _api;
  final AppDatabase _db;
  bool _corriendo = false;
  bool _repetir = false;

  /// Un ciclo completo. Si ya hay uno en curso no lanza otro en paralelo,
  /// pero deja anotado que hay que repetir: lo escrito mientras subía sale en
  /// el ciclo siguiente en vez de esperar al próximo disparador.
  Future<void> sincronizar() async {
    if (_corriendo) {
      _repetir = true;
      return;
    }
    _corriendo = true;
    try {
      do {
        _repetir = false;
        await _ciclo();
      } while (_repetir);
    } finally {
      _corriendo = false;
    }
  }

  Future<void> _ciclo() async {
    if (!await _empujarRegistros()) return;
    if (!await _empujarFotos()) return;
    await bajarCatalogo();
    await _completarFinalizadas();
  }

  // ------------------------------------------------------------- registros

  /// `false` si hay que detener el ciclo (sin red o error del servidor).
  Future<bool> _empujarRegistros() async {
    final pendientes =
        await (_db.select(_db.registroEjecucion)
              ..where(
                (t) => t.estado.equalsValue(EstadoRegistroEjecucion.pendiente),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.secuencia)]))
            .get();
    for (final fila in pendientes) {
      try {
        await _api.post(
          '/api/solicitudes/${fila.solicitudId}/${fila.tipo}',
          data: {
            ...jsonDecode(fila.payload) as Map<String, dynamic>,
            'uuid_cliente': fila.uuidCliente,
            'secuencia': fila.secuencia,
          },
        );
        await _marcarRegistro(
          fila.uuidCliente,
          EstadoRegistroEjecucion.confirmado,
        );
      } on ApiExcepcionServidor catch (e) {
        if (_esTransitorio(e.codigo)) return false;
        await _marcarRegistro(
          fila.uuidCliente,
          EstadoRegistroEjecucion.rechazado,
          motivo: _motivo(e),
        );
      } on ApiExcepcion {
        return false;
      }
    }
    return true;
  }

  Future<void> _marcarRegistro(
    String uuidCliente,
    EstadoRegistroEjecucion estado, {
    String? motivo,
  }) {
    // El `where` excluye lo ya confirmado: no se reescribe (invariante 6).
    return (_db.update(_db.registroEjecucion)..where(
          (t) =>
              t.uuidCliente.equals(uuidCliente) &
              t.estado.equalsValue(EstadoRegistroEjecucion.confirmado).not(),
        ))
        .write(
          RegistroEjecucionCompanion(
            estado: Value(estado),
            motivoRechazo: Value(motivo),
          ),
        );
  }

  // ----------------------------------------------------------------- fotos

  Future<bool> _empujarFotos() async {
    final pendientes = await (_db.select(
      _db.fotoEjecucion,
    )..where((t) => t.estado.equalsValue(EstadoFotoEjecucion.pendiente))).get();
    for (final fila in pendientes) {
      if (!File(fila.rutaArchivoLocal).existsSync()) {
        await _marcarFoto(
          fila.uuidCliente,
          EstadoFotoEjecucion.rechazado,
          motivo: 'El archivo de la foto ya no está en el teléfono.',
        );
        continue;
      }
      try {
        await _api.post(
          '/api/solicitudes/${fila.solicitudId}/evidencias',
          data: FormData.fromMap({
            'uuid_cliente': fila.uuidCliente,
            'tipo': fila.tipo,
            'avance_uuid_cliente': ?fila.avanceUuidCliente,
            'archivo': await MultipartFile.fromFile(
              fila.rutaArchivoLocal,
              filename: '${fila.uuidCliente}.jpg',
            ),
          }),
        );
        await _marcarFoto(fila.uuidCliente, EstadoFotoEjecucion.subido);
      } on ApiExcepcionServidor catch (e) {
        if (_esTransitorio(e.codigo)) return false;
        await _marcarFoto(
          fila.uuidCliente,
          EstadoFotoEjecucion.rechazado,
          motivo: _motivo(e),
        );
      } on ApiExcepcion {
        return false;
      }
    }
    return true;
  }

  Future<void> _marcarFoto(
    String uuidCliente,
    EstadoFotoEjecucion estado, {
    String? motivo,
  }) {
    return (_db.update(_db.fotoEjecucion)..where(
          (t) =>
              t.uuidCliente.equals(uuidCliente) &
              t.estado.equalsValue(EstadoFotoEjecucion.subido).not(),
        ))
        .write(
          FotoEjecucionCompanion(
            estado: Value(estado),
            motivoRechazo: Value(motivo),
          ),
        );
  }

  // -------------------------------------------------------------- catálogo

  /// Baja `servicios_asignados` y los espeja. No pisa el estado ni el avance
  /// de una solicitud con registros todavía sin subir: lo que el piloto hizo
  /// sin señal vale más que lo que el servidor aún no sabe. Un servicio que
  /// el servidor ya no entrega se oculta, no se borra.
  Future<void> bajarCatalogo() async {
    final Response<dynamic> respuesta;
    try {
      respuesta = await _api.get('/api/sync/catalogo');
    } on ApiExcepcion {
      return;
    }
    final cuerpo = Map<String, dynamic>.from(respuesta.data as Map);
    final servicios = [
      for (final s in (cuerpo['servicios_asignados'] as List? ?? const []))
        Map<String, dynamic>.from(s as Map),
    ];
    await _db.transaction(() async {
      final conPendientes = <int>{
        for (final r
            in await (_db.select(_db.registroEjecucion)..where(
                  (t) =>
                      t.estado.equalsValue(EstadoRegistroEjecucion.pendiente),
                ))
                .get())
          r.solicitudId,
      };
      final vistos = <int>{};
      for (final s in servicios) {
        final id = s['id'] as int;
        vistos.add(id);
        final base = _companionDeCatalogo(s);
        final local = await (_db.select(
          _db.servicioAdjudicado,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local == null) {
          await _db.into(_db.servicioAdjudicado).insert(base);
        } else if (conPendientes.contains(id)) {
          // Conserva lo hecho sin señal: estado y avance locales.
          await (_db.update(
            _db.servicioAdjudicado,
          )..where((t) => t.id.equals(id))).write(
            base.copyWith(
              estado: const Value.absent(),
              hectareasEjecutadas: const Value.absent(),
              porcentajeAvance: const Value.absent(),
            ),
          );
        } else if (local.estado == 'finalizada') {
          // Ya cerrado en este dispositivo y confirmado: el catálogo no lo
          // devuelve más; si llegara, no se retrocede.
          continue;
        } else {
          await (_db.update(
            _db.servicioAdjudicado,
          )..where((t) => t.id.equals(id))).write(base);
        }
      }
      // Lo que el servidor ya no entrega se oculta, salvo lo finalizado
      // (se sigue viendo con su precio final) y lo que tiene trabajo sin
      // subir.
      final locales = await _db.select(_db.servicioAdjudicado).get();
      for (final l in locales) {
        if (vistos.contains(l.id) ||
            l.oculto ||
            l.estado == 'finalizada' ||
            conPendientes.contains(l.id)) {
          continue;
        }
        await (_db.update(_db.servicioAdjudicado)
              ..where((t) => t.id.equals(l.id)))
            .write(const ServicioAdjudicadoCompanion(oculto: Value(true)));
      }
    });
  }

  ServicioAdjudicadoCompanion _companionDeCatalogo(Map<String, dynamic> s) {
    return ServicioAdjudicadoCompanion(
      id: Value(s['id'] as int),
      uuidCliente: Value('${s['uuid_cliente']}'),
      estado: Value('${s['estado']}'),
      tipoAplicacion: Value('${s['tipo_aplicacion']}'),
      hectareasSolicitadas: Value(
        MapeoNegociacion.decimal(s['hectareas_solicitadas']),
      ),
      cultivo: Value(s['cultivo'] as String?),
      productoIndicado: Value('${s['producto_indicado'] ?? ''}'),
      aportaProducto: Value('${s['aporta_producto'] ?? ''}'),
      ventanaDesde: Value('${s['ventana_desde'] ?? ''}'),
      ventanaHasta: Value('${s['ventana_hasta'] ?? ''}'),
      urgente: Value(s['urgente'] == true),
      observaciones: Value(s['observaciones'] as String?),
      terrenoJson: Value(jsonEncode(s['terreno'] ?? const {})),
      precioHaPropuesto: Value(
        MapeoNegociacion.decimalOpcional(s['precio_ha_propuesto']),
      ),
      precioHaAcordado: Value(
        MapeoNegociacion.decimalOpcional(s['precio_ha_acordado']),
      ),
      hectareasEjecutadas: Value(
        MapeoNegociacion.decimalOpcional(s['hectareas_ejecutadas']),
      ),
      porcentajeAvance: Value(
        MapeoNegociacion.decimalOpcional(s['porcentaje_avance']),
      ),
      contactoNombre: Value(
        (s['contacto'] is Map)
            ? (s['contacto'] as Map)['nombre'] as String?
            : null,
      ),
      contactoTelefono: Value(
        (s['contacto'] is Map)
            ? (s['contacto'] as Map)['telefono'] as String?
            : null,
      ),
      oculto: const Value(false),
    );
  }

  /// Para los servicios finalizados aquí cuyo monto el servidor todavía no
  /// devolvió, lo pide a `GET /api/solicitudes/{id}/avance`.
  Future<void> _completarFinalizadas() async {
    final filas =
        await (_db.select(_db.servicioAdjudicado)..where(
              (t) => t.estado.equals('finalizada') & t.montoFinal.isNull(),
            ))
            .get();
    for (final f in filas) {
      final cierre =
          await (_db.select(_db.registroEjecucion)..where(
                (t) =>
                    t.solicitudId.equals(f.id) &
                    t.tipo.equals('cierre') &
                    t.estado.equalsValue(EstadoRegistroEjecucion.confirmado),
              ))
              .getSingleOrNull();
      if (cierre == null) continue;
      try {
        final r = await _api.get('/api/solicitudes/${f.id}/avance');
        final avance = (r.data as Map)['avance'] as Map?;
        final monto = MapeoNegociacion.decimalOpcional(avance?['monto_final']);
        if (monto != null) {
          await (_db.update(_db.servicioAdjudicado)
                ..where((t) => t.id.equals(f.id)))
              .write(ServicioAdjudicadoCompanion(montoFinal: Value(monto)));
        }
      } on ApiExcepcion {
        return;
      }
    }
  }

  // --------------------------------------------------------------- ayudas

  /// Red caída, sesión vencida o servidor con problemas: reintentar luego.
  static bool _esTransitorio(int codigo) =>
      codigo == 401 || codigo == 408 || codigo == 429 || codigo >= 500;

  static String _motivo(ApiExcepcionServidor e) {
    final cuerpo = e.cuerpo;
    if (cuerpo is Map && cuerpo['message'] is String) {
      return cuerpo['message'] as String;
    }
    return 'No pudimos aceptar el envío (${e.codigo}).';
  }
}
