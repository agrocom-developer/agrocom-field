import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../db/database.dart';
import '../../../../db/tablas/foto_ejecucion.dart';
import '../../../../db/tablas/registro_ejecucion.dart';
import '../../../../evidencias/compresor_evidencia.dart';
import '../../../../evidencias/hash_evidencia.dart';
import '../../../dominio/dominio.dart';
import '../../negociacion/data/mapeo_negociacion.dart';
import '../domain/ejecucion.dart';

/// La ejecución de un servicio adjudicado sobre `drift` (ADR 0016): la UI
/// lee de acá y toda escritura es insertar local + encolar en UNA
/// transacción (invariante 3 de CLAUDE.md). No toca la red; la subida la
/// hace `EjecucionSyncEngine`.
class EjecucionLocal implements EjecucionRepositorio {
  EjecucionLocal(
    this._db, {
    required CompresorEvidencia compresor,
    required Directory directorioFotos,
    Uuid? uuid,
    DateTime Function()? reloj,
    Future<void> Function()? sincronizar,
  }) : _compresor = compresor,
       _directorio = directorioFotos,
       _uuid = uuid ?? const Uuid(),
       _reloj = reloj ?? DateTime.now,
       _sincronizar = sincronizar;

  final AppDatabase _db;
  final CompresorEvidencia _compresor;
  final Directory _directorio;
  final Uuid _uuid;
  final DateTime Function() _reloj;
  final Future<void> Function()? _sincronizar;

  // ---------------------------------------------------------------- lectura

  Stream<T> _cuandoCambia<T>(Future<T> Function() leer) async* {
    yield await leer();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.servicioAdjudicado,
        _db.registroEjecucion,
        _db.fotoEjecucion,
      ]),
    )) {
      yield await leer();
    }
  }

  @override
  Stream<List<ServicioEnLote>> observar() => _cuandoCambia(_leerTodos);

  @override
  Stream<ServicioEnLote?> observarUno(int id) =>
      _cuandoCambia(() async => _leerUno(id));

  Future<List<ServicioEnLote>> _leerTodos() async {
    final filas =
        await (_db.select(_db.servicioAdjudicado)
              ..where((t) => t.oculto.equals(false))
              ..orderBy([(t) => OrderingTerm.asc(t.ventanaDesde)]))
            .get();
    final servicios = [for (final f in filas) await _aDominio(f)];
    // Primero lo que se está ejecutando, luego lo que espera, al final lo
    // finalizado.
    int peso(ServicioEnLote s) => switch (s.estado) {
      EstadoServicioLote.enEjecucion => 0,
      EstadoServicioLote.adjudicada => 1,
      EstadoServicioLote.finalizada => 2,
    };
    final indices = {
      for (var i = 0; i < servicios.length; i++) servicios[i].id: i,
    };
    return servicios..sort((a, b) {
      final p = peso(a).compareTo(peso(b));
      return p != 0 ? p : indices[a.id]!.compareTo(indices[b.id]!);
    });
  }

  Future<ServicioEnLote?> _leerUno(int id) async {
    final fila = await (_db.select(
      _db.servicioAdjudicado,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return fila == null ? null : _aDominio(fila);
  }

  Future<ServicioEnLote> _aDominio(ServicioAdjudicadoData f) async {
    final registros = await (_db.select(
      _db.registroEjecucion,
    )..where((t) => t.solicitudId.equals(f.id))).get();
    final fotos = await (_db.select(
      _db.fotoEjecucion,
    )..where((t) => t.solicitudId.equals(f.id))).get();
    final terreno = _terreno(f);
    final terrenoMapa = f.terrenoJson.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(f.terrenoJson) as Map);
    return ServicioEnLote(
      id: f.id,
      uuidCliente: f.uuidCliente,
      estado: EstadoServicioLote.deCodigo(f.estado),
      hectareas: f.hectareasSolicitadas,
      tipoAplicacion: f.tipoAplicacion,
      cultivo: f.cultivo,
      producto: f.productoIndicado,
      aportaProducto: f.aportaProducto,
      ventanaDesde: DateTime.tryParse(f.ventanaDesde),
      ventanaHasta: DateTime.tryParse(f.ventanaHasta),
      urgente: f.urgente,
      observaciones: f.observaciones,
      terreno: terreno,
      accesoDificil: terrenoMapa['acceso_dificil'] == true,
      referenciasAcceso: terrenoMapa['referencias_acceso'] as String?,
      colindantesSensibles: terrenoMapa['colindantes_sensibles'] as String?,
      precioHaAcordado: f.precioHaAcordado,
      hectareasEjecutadas: f.hectareasEjecutadas,
      porcentaje: f.porcentajeAvance,
      montoFinal: f.montoFinal,
      contactoNombre: f.contactoNombre,
      contactoTelefono: f.contactoTelefono,
      registrosPendientes: registros
          .where((r) => r.estado == EstadoRegistroEjecucion.pendiente)
          .length,
      fotosPendientes: fotos
          .where((p) => p.estado == EstadoFotoEjecucion.pendiente)
          .length,
      fotosTotal: fotos.length,
      rechazos:
          registros
              .where((r) => r.estado == EstadoRegistroEjecucion.rechazado)
              .length +
          fotos.where((p) => p.estado == EstadoFotoEjecucion.rechazado).length,
    );
  }

  Lote? _terreno(ServicioAdjudicadoData f) {
    if (f.terrenoJson.isEmpty) return null;
    final t = Map<String, dynamic>.from(jsonDecode(f.terrenoJson) as Map);
    final poligono = MapeoNegociacion.poligono(t['geometria']);
    if (poligono.length < 3) return null;
    return Lote(
      id: 'servicio-${f.id}',
      nombre: '${t['nombre'] ?? 'Terreno'}',
      zona: '',
      cultivo: f.cultivo ?? '',
      hectareas: MapeoNegociacion.decimal(t['hectareas']),
      poligono: poligono,
    );
  }

  // -------------------------------------------------------------- escritura

  /// Inserta el registro en la cola y actualiza el espejo, en una sola
  /// transacción. La secuencia sale del máximo local + 1: el orden causal no
  /// depende del reloj (invariante 5).
  Future<String> _encolar(
    int solicitudId,
    String tipo,
    Map<String, dynamic> payload, {
    ServicioAdjudicadoCompanion? cambios,
  }) {
    return _db.transaction(() async {
      final maximo = await _db
          .customSelect(
            'SELECT COALESCE(MAX(secuencia), 0) AS m FROM registro_ejecucion',
            readsFrom: {_db.registroEjecucion},
          )
          .getSingle();
      final uuidCliente = _uuid.v4();
      await _db
          .into(_db.registroEjecucion)
          .insert(
            RegistroEjecucionCompanion.insert(
              uuidCliente: uuidCliente,
              solicitudId: solicitudId,
              tipo: tipo,
              payload: jsonEncode(payload),
              secuencia: maximo.read<int>('m') + 1,
            ),
          );
      if (cambios != null) {
        await (_db.update(
          _db.servicioAdjudicado,
        )..where((t) => t.id.equals(solicitudId))).write(cambios);
      }
      return uuidCliente;
    });
  }

  String _ahora() => _reloj().toUtc().toIso8601String();

  @override
  Future<void> iniciar(int id) async {
    final s = await _leerUno(id);
    if (s == null || s.estado != EstadoServicioLote.adjudicada) return;
    await _encolar(
      id,
      'inicio',
      {'registrado_en': _ahora()},
      cambios: ServicioAdjudicadoCompanion(
        estado: Value(EstadoServicioLote.enEjecucion.codigo),
      ),
    );
    unawaited(sincronizarAhora());
  }

  @override
  Future<void> marcarAvance(
    int id, {
    Decimal? hectareas,
    Decimal? porcentaje,
    String? nota,
    String? motivoCorreccion,
  }) async {
    assert(
      (hectareas == null) != (porcentaje == null),
      'Se marca el avance con hectáreas o con porcentaje, no con ambos',
    );
    final s = await _leerUno(id);
    if (s == null || s.estado != EstadoServicioLote.enEjecucion) return;
    final cien = Decimal.fromInt(100);
    final ejecutadas =
        hectareas ??
        (s.hectareas * porcentaje! / cien).toDecimal(
          scaleOnInfinitePrecision: 4,
        );
    final pct =
        porcentaje ??
        (s.hectareas == Decimal.zero
            ? Decimal.zero
            : (hectareas! * cien / s.hectareas).toDecimal(
                scaleOnInfinitePrecision: 2,
              ));
    await _encolar(
      id,
      'avance',
      {
        if (hectareas != null) 'hectareas_ejecutadas': hectareas.toString(),
        if (porcentaje != null) 'porcentaje': porcentaje.toString(),
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        if (motivoCorreccion != null && motivoCorreccion.trim().isNotEmpty)
          'motivo_correccion': motivoCorreccion.trim(),
        'registrado_en': _ahora(),
      },
      cambios: ServicioAdjudicadoCompanion(
        hectareasEjecutadas: Value(ejecutadas),
        porcentajeAvance: Value(pct),
      ),
    );
    unawaited(sincronizarAhora());
  }

  @override
  Future<String> adjuntarFoto(
    int id,
    Uint8List bytes, {
    TipoFotoEjecucion tipo = TipoFotoEjecucion.avance,
  }) async {
    // Fuera de la transacción: comprimir y escribir el archivo es lento y no
    // es una operación de base.
    final comprimido = await _compresor.comprimir(bytes);
    final uuidCliente = _uuid.v4();
    if (!_directorio.existsSync()) {
      await _directorio.create(recursive: true);
    }
    final archivo = File('${_directorio.path}/$uuidCliente.jpg');
    await archivo.writeAsBytes(comprimido, flush: true);
    await _db.transaction(() async {
      // La foto cuelga del último avance marcado, si lo hay.
      final avance =
          await (_db.select(_db.registroEjecucion)
                ..where(
                  (t) => t.solicitudId.equals(id) & t.tipo.equals('avance'),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.secuencia)])
                ..limit(1))
              .getSingleOrNull();
      await _db
          .into(_db.fotoEjecucion)
          .insert(
            FotoEjecucionCompanion.insert(
              uuidCliente: uuidCliente,
              solicitudId: id,
              tipo: tipo.codigo,
              avanceUuidCliente: Value(avance?.uuidCliente),
              rutaArchivoLocal: archivo.path,
              hashSha256: calcularHashEvidencia(comprimido),
              fecha: _reloj(),
            ),
          );
    });
    unawaited(sincronizarAhora());
    return uuidCliente;
  }

  @override
  Future<void> finalizar(
    int id, {
    required Decimal hectareasEjecutadas,
    String? nota,
  }) async {
    final s = await _leerUno(id);
    if (s == null || s.estado != EstadoServicioLote.enEjecucion) return;
    final pct = s.hectareas == Decimal.zero
        ? Decimal.zero
        : (hectareasEjecutadas * Decimal.fromInt(100) / s.hectareas).toDecimal(
            scaleOnInfinitePrecision: 2,
          );
    await _encolar(
      id,
      'cierre',
      {
        'hectareas_ejecutadas': hectareasEjecutadas.toString(),
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        'registrado_en': _ahora(),
      },
      cambios: ServicioAdjudicadoCompanion(
        estado: Value(EstadoServicioLote.finalizada.codigo),
        hectareasEjecutadas: Value(hectareasEjecutadas),
        porcentajeAvance: Value(pct),
      ),
    );
    unawaited(sincronizarAhora());
  }

  @override
  Future<void> sincronizarAhora() async {
    try {
      await _sincronizar?.call();
    } on Object {
      // Sin red o sin sesión: lo pendiente espera al próximo ciclo.
    }
  }

  @override
  Future<void> limpiarAlCerrarSesion() async {
    final rutas = <String>[];
    await _db.transaction(() async {
      final registros = await _db.select(_db.registroEjecucion).get();
      final fotos = await _db.select(_db.fotoEjecucion).get();
      // Lo que todavía no se subió es trabajo de campo: se conserva con su
      // servicio, aunque el próximo usuario no lo vea.
      final conPendientes = <int>{
        for (final r in registros)
          if (r.estado == EstadoRegistroEjecucion.pendiente) r.solicitudId,
        for (final f in fotos)
          if (f.estado == EstadoFotoEjecucion.pendiente) f.solicitudId,
      };
      await (_db.delete(
        _db.servicioAdjudicado,
      )..where((t) => t.id.isNotIn(conPendientes))).go();
      await (_db.delete(_db.registroEjecucion)..where(
            (t) =>
                t.estado.equalsValue(EstadoRegistroEjecucion.pendiente).not() &
                t.solicitudId.isNotIn(conPendientes),
          ))
          .go();
      for (final f in fotos) {
        if (f.estado != EstadoFotoEjecucion.pendiente &&
            !conPendientes.contains(f.solicitudId)) {
          rutas.add(f.rutaArchivoLocal);
        }
      }
      await (_db.delete(_db.fotoEjecucion)..where(
            (t) =>
                t.estado.equalsValue(EstadoFotoEjecucion.pendiente).not() &
                t.solicitudId.isNotIn(conPendientes),
          ))
          .go();
    });
    for (final ruta in rutas) {
      try {
        File(ruta).deleteSync();
      } on FileSystemException {
        // Ya no estaba.
      }
    }
  }
}
