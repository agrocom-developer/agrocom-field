import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/db/database.dart';
import '../../../nucleo/db/tablas/sesion_local.dart' show EstadoSesionLocal;
import '../domain/auxiliar.dart';
import '../domain/reglas_apertura.dart';
import '../domain/reglas_condiciones.dart';
import '../domain/reglas_sesion.dart';
import '../domain/sesion.dart';

/// Escribe la apertura y el cierre de una sesión de vuelo (`AperturaSesion`
/// / `CierreSesion`, ver esos contratos en `agrocom-api`): inserta/actualiza
/// [SesionLocal] y encola en `ColaSync` en una sola transacción (invariante
/// 3 de CLAUDE.md) — ningún caso de uso espera la red para confirmar en
/// pantalla.
class SesionRepository {
  SesionRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// Lanza [TrabajoInexistenteExcepcion] o [ObservacionAgronomoRequeridaExcepcion]
  /// ANTES de escribir nada (ni [SesionLocal] ni [CondicionLocal] ni
  /// `ColaSync`) — la segunda si [vientoKmh]/[temperaturaC]/[humedadPct] caen
  /// fuera de rango y falta [observacionAgronomo] u [firmaObservacion]: el
  /// servidor va a rechazar igual ese registro (contrato explícito), así que
  /// no tiene sentido encolarlo para enterarse recién con señal. [inicio] es
  /// obligatorio, no `DateTime.now()` interno, por el mismo motivo que en
  /// `TrabajoRepository.abrirTrabajo`.
  ///
  /// Las condiciones climáticas viajan como un registro `condiciones`
  /// separado (propio `uuid_cliente`, referenciando esta sesión por
  /// [CondicionLocal.sesionUuidCliente]) — nunca como columnas de la sesión:
  /// el contrato real (`RegistroSync` en `docs/api/openapi.yaml`) los separa
  /// porque `momento` podría crecer más allá de `inicio_sesion` a futuro.
  ///
  /// [auxiliarId]/[dronId]/[hectareaInicialAcumulada] son HU-07 — los tres
  /// opcionales: `null` cuando la sesión no tiene auxiliar asignado, el dron
  /// no tiene id de servidor conocido todavía, o no es un relevo (primera
  /// sesión del lote, sin acumulado previo que registrar).
  Future<Sesion> abrirSesion({
    required String trabajoUuidCliente,
    required int pilotoId,
    int? auxiliarId,
    int? dronId,
    Decimal? hectareasDeclaradas,
    Decimal? hectareaInicialAcumulada,
    required DateTime inicio,
    required Decimal vientoKmh,
    required Decimal temperaturaC,
    required Decimal humedadPct,
    String? observacionAgronomo,
    String? firmaObservacion,
  }) async {
    final trabajoExiste = await _existeTrabajo(trabajoUuidCliente);
    verificarTrabajoExiste(
      trabajoExiste: trabajoExiste,
      trabajoUuidCliente: trabajoUuidCliente,
    );

    // Los límites efectivos del trabajo, los mismos con los que el servidor
    // va a validar el registro `condiciones` (tarea 24).
    final fueraDeRango = condicionesFueraDeRango(
      vientoKmh: vientoKmh,
      temperaturaC: temperaturaC,
      humedadPct: humedadPct,
      limites: await limitesCondiciones(trabajoUuidCliente),
    );
    verificarObservacionSiFueraDeRango(
      fueraDeRango: fueraDeRango,
      observacionAgronomo: observacionAgronomo,
      firmaObservacion: firmaObservacion,
    );

    final uuidCliente = _uuid.v4();
    final uuidClienteCondicion = _uuid.v4();
    final hectareas = hectareasDeclaradas ?? Decimal.parse('0');

    return _db.transaction(() async {
      final sesionesPrevias = await _contarSesionesDeTrabajo(
        trabajoUuidCliente,
      );
      final secuenciaSesion = proximaSecuenciaSesion(sesionesPrevias);

      await _db
          .into(_db.sesionLocal)
          .insert(
            SesionLocalCompanion.insert(
              uuidCliente: uuidCliente,
              trabajoUuidCliente: trabajoUuidCliente,
              secuencia: secuenciaSesion,
              pilotoId: pilotoId,
              auxiliarId: Value(auxiliarId),
              dronId: Value(dronId),
              hectareasDeclaradas: Value(hectareas),
              hectareaInicialAcumulada: Value(hectareaInicialAcumulada),
              inicio: inicio,
            ),
          );

      final secuenciaSesionGlobal = await _proximaSecuenciaGlobal();
      await _db
          .into(_db.colaSync)
          .insert(
            ColaSyncCompanion.insert(
              uuidCliente: uuidCliente,
              tipoEntidad: 'sesion',
              // Sin `tipo`/`uuid_cliente` en el payload — ver el mismo
              // comentario en `TrabajoRepository.abrirTrabajo`.
              payload: jsonEncode({
                'trabajo_uuid_cliente': trabajoUuidCliente,
                'secuencia': secuenciaSesion,
                'piloto_id': pilotoId,
                'auxiliar_id': auxiliarId,
                'dron_id': dronId,
                'hectareas_declaradas': hectareas.toString(),
                'hectarea_inicial_acumulada': hectareaInicialAcumulada
                    ?.toString(),
                'inicio': inicio.toUtc().toIso8601String(),
              }),
              secuencia: secuenciaSesionGlobal,
            ),
          );

      await _db
          .into(_db.condicionLocal)
          .insert(
            CondicionLocalCompanion.insert(
              uuidCliente: uuidClienteCondicion,
              sesionUuidCliente: uuidCliente,
              momento: 'inicio_sesion',
              vientoKmh: vientoKmh,
              temperaturaC: temperaturaC,
              humedadPct: humedadPct,
              observacionAgronomo: Value(observacionAgronomo),
              firmaObservacion: Value(firmaObservacion),
            ),
          );

      // Secuencia global propia, después de la de `sesion` (invariante 5 de
      // CLAUDE.md: orden causal explícito, nunca por reloj de dispositivo).
      final secuenciaCondicionGlobal = await _proximaSecuenciaGlobal();
      await _db
          .into(_db.colaSync)
          .insert(
            ColaSyncCompanion.insert(
              uuidCliente: uuidClienteCondicion,
              tipoEntidad: 'condiciones',
              payload: jsonEncode({
                'sesion_uuid_cliente': uuidCliente,
                'momento': 'inicio_sesion',
                'viento_kmh': vientoKmh.toString(),
                'temperatura_c': temperaturaC.toString(),
                'humedad_pct': humedadPct.toString(),
                'observacion_agronomo': observacionAgronomo,
                'firma_observacion': firmaObservacion,
              }),
              secuencia: secuenciaCondicionGlobal,
            ),
          );

      return Sesion(
        uuidCliente: uuidCliente,
        trabajoUuidCliente: trabajoUuidCliente,
        secuencia: secuenciaSesion,
        pilotoId: pilotoId,
        auxiliarId: auxiliarId,
        dronId: dronId,
        hectareasDeclaradas: hectareas,
        hectareaInicialAcumulada: hectareaInicialAcumulada,
        inicio: inicio,
        estado: EstadoSesion.abierta,
      );
    });
  }

  /// Actualiza la MISMA fila de [SesionLocal] con los campos de cierre, sin
  /// tocar `hectareasDeclaradas`/`inicio` de apertura (invariante 6 de
  /// CLAUDE.md), y encola `cierre_sesion` — un evento nuevo con su propio
  /// `uuid_cliente` ([uuidClienteCierre]), nunca el `uuid_cliente` de
  /// apertura de la sesión. Todo dentro de una sola transacción (invariante
  /// 3 de CLAUDE.md).
  ///
  /// Esta app no decide localmente que la sesión "está cerrada" para el
  /// servidor (invariante 7 de CLAUDE.md): [EstadoSesion.cerrada] acá es
  /// solo el modelo local de lo que el dispositivo propuso — la
  /// confirmación de servidor viaja por separado, en el `EstadoSync` de la
  /// fila de `ColaSync`.
  ///
  /// [hectareasDeclaradas] es el ingreso directo, comportamiento de siempre.
  /// [hectareaFinalAcumulada] es HU-07: cuando la sesión abrió con
  /// `hectareaInicialAcumulada` no nulo, ESE es el dato que hay que pasar acá
  /// — el repositorio decide cuál de los dos usar leyendo el valor ya
  /// persistido en la apertura (no un flag que mande el llamador) y calcula
  /// la diferencia con `calcularHectareasDeCierrePorAcumulado`, que puede
  /// lanzar [AcumuladoFinalMenorQueInicialExcepcion] ANTES de escribir nada.
  /// Si la sesión no tiene acumulado inicial, sigue funcionando exactamente
  /// como antes de esta HU — [hectareasDeclaradas] es entonces obligatorio,
  /// igual que la UI solo pide uno de los dos campos según corresponda (ver
  /// `sesion_vuelo_vista.dart`).
  Future<Sesion> cerrarSesion({
    required String sesionUuidCliente,
    required DateTime fin,
    required String motivoCierre,
    Decimal? hectareasDeclaradas,
    Decimal? hectareaFinalAcumulada,
    Decimal? litrosConsumidos,
  }) async {
    final sesionPrevia = await (_db.select(
      _db.sesionLocal,
    )..where((t) => t.uuidCliente.equals(sesionUuidCliente))).getSingle();
    final hectareaInicial = sesionPrevia.hectareaInicialAcumulada;

    final hectareasCierre = hectareaInicial != null
        ? calcularHectareasDeCierrePorAcumulado(
            hectareaInicialAcumulada: hectareaInicial,
            hectareaFinalAcumulada: hectareaFinalAcumulada!,
          )
        : hectareasDeclaradas!;

    final uuidClienteCierre = _uuid.v4();

    return _db.transaction(() async {
      await (_db.update(
        _db.sesionLocal,
      )..where((t) => t.uuidCliente.equals(sesionUuidCliente))).write(
        SesionLocalCompanion(
          estado: const Value(EstadoSesionLocal.cerrada),
          fin: Value(fin),
          motivoCierre: Value(motivoCierre),
          hectareasDeclaradasCierre: Value(hectareasCierre),
          litrosConsumidos: Value(litrosConsumidos),
          uuidClienteCierre: Value(uuidClienteCierre),
        ),
      );

      final secuenciaGlobal = await _proximaSecuenciaGlobal();
      await _db
          .into(_db.colaSync)
          .insert(
            ColaSyncCompanion.insert(
              uuidCliente: uuidClienteCierre,
              tipoEntidad: 'cierre_sesion',
              payload: jsonEncode({
                'sesion_uuid_cliente': sesionUuidCliente,
                'fin': fin.toUtc().toIso8601String(),
                'motivo_cierre': motivoCierre,
                'hectareas_declaradas': hectareasCierre.toString(),
                'litros_consumidos': litrosConsumidos?.toString(),
              }),
              secuencia: secuenciaGlobal,
            ),
          );

      final fila = await (_db.select(
        _db.sesionLocal,
      )..where((t) => t.uuidCliente.equals(sesionUuidCliente))).getSingle();
      return _sesionDesdeFila(fila);
    });
  }

  /// Límites efectivos del trabajo [trabajoUuidCliente] para decidir las
  /// condiciones de apertura (tarea 24), leídos de `drift` (invariante 1 de
  /// CLAUDE.md). Mismo criterio que `Trabajo::limitesEfectivos()` de
  /// `agrocom-api`:
  ///
  /// - Trabajo asignado desde el panel: la fila de `trabajo_catalogo` con
  ///   ese `uuid_cliente`, que el servidor ya manda resuelta (#309). Un
  ///   límite en `null` hereda el default igual.
  /// - Trabajo abierto por la app (`abrirTrabajo`): no tiene fila en
  ///   `trabajo_catalogo` ni Orden de Trabajo en el servidor, así que usa
  ///   los defaults del sistema, igual que el servidor.
  ///
  /// Sin `Stream`, mismo criterio que [auxiliaresDisponibles]: el formulario
  /// la pide una sola vez al abrirse.
  Future<LimitesCondiciones> limitesCondiciones(
    String trabajoUuidCliente,
  ) async {
    final trabajo =
        await (_db.select(_db.trabajoCatalogo)
              ..where((t) => t.uuidCliente.equals(trabajoUuidCliente)))
            .getSingleOrNull();
    if (trabajo == null) return LimitesCondiciones.porDefecto();
    // Trabajo retirado (tareas 26 y 28): desde `agrocom-api` #314 (develop
    // `add36c2b`), `registrarCondiciones` carga el trabajo con
    // `withTrashed()` y usa los límites de su Orden de Trabajo con cualquier
    // motivo de retiro — `dado_de_baja` incluido, que antes caía a los
    // defaults. Son los de esta fila (la última versión que llegó); en
    // blanco, heredan el default, igual que el servidor. `fuera_de_alcance`
    // (motivo local del barrido) usa lo último que conoce, por el mismo
    // criterio.
    //
    // Divergencia conocida: si la Orden de Trabajo misma se da de baja
    // después de retirado el trabajo, el servidor vuelve a los defaults y
    // la app no se entera, porque el catálogo ya no reenvía un trabajo
    // retirado. Caso raro, anotado en la petición del 1/10/2026.
    return LimitesCondiciones.resolver(
      vientoMaxKmh: trabajo.vientoMaxKmh,
      temperaturaMaxC: trabajo.temperaturaMaxC,
      humedadMaxPct: trabajo.humedadMaxPct,
      humedadMinPct: trabajo.humedadMinPct,
    );
  }

  /// La sesión abierta de [trabajoUuidCliente] en este dispositivo, o `null`
  /// (tarea 27): es con la que arranca `SesionBloc` al volver a la
  /// pantalla, con su `uuid_cliente` de siempre — nunca uno nuevo
  /// (invariante 2 de CLAUDE.md). Si hubiera más de una abierta, la de
  /// `secuencia` mayor dentro del trabajo (invariante 5: el orden lo da la
  /// secuencia local, nunca el reloj).
  Future<Sesion?> sesionAbiertaDeTrabajo(String trabajoUuidCliente) async {
    final fila =
        await (_db.select(_db.sesionLocal)
              ..where(
                (t) =>
                    t.trabajoUuidCliente.equals(trabajoUuidCliente) &
                    t.estado.equalsValue(EstadoSesionLocal.abierta),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.secuencia)])
              ..limit(1))
            .getSingleOrNull();
    return fila == null ? null : _sesionDesdeFila(fila);
  }

  /// Si se puede abrir una sesión nueva sobre [trabajoUuidCliente] (tarea
  /// 27), leído de `drift` y decidido por `restriccionApertura`. Sin
  /// `Stream`, mismo criterio que [limitesCondiciones]: el formulario la
  /// pide al abrirse.
  Future<RestriccionApertura> restriccionAperturaDeTrabajo(
    String trabajoUuidCliente,
  ) async {
    final abierta =
        await (_db.select(_db.sesionLocal)
              ..where((t) => t.estado.equalsValue(EstadoSesionLocal.abierta))
              ..limit(1))
            .getSingleOrNull();
    // La orden sale de `TrabajoLocal` (siempre está: sin él no se abre
    // sesión) o, si faltara, de la fila del catálogo.
    final trabajoLocal =
        await (_db.select(_db.trabajoLocal)
              ..where((t) => t.uuidCliente.equals(trabajoUuidCliente)))
            .getSingleOrNull();
    final trabajoCatalogo =
        await (_db.select(_db.trabajoCatalogo)
              ..where((t) => t.uuidCliente.equals(trabajoUuidCliente)))
            .getSingleOrNull();
    final ordenId = trabajoLocal?.ordenId ?? trabajoCatalogo?.ordenId;
    final orden = ordenId == null
        ? null
        : await (_db.select(
            _db.ordenCatalogo,
          )..where((t) => t.id.equals(ordenId))).getSingleOrNull();
    return restriccionApertura(
      haySesionAbierta: abierta != null,
      motivoRetiroOrden: orden?.motivoRetiro,
      motivoRetiroTrabajo: trabajoCatalogo?.motivoRetiro,
    );
  }

  /// Auxiliares activos disponibles para el dropdown del formulario de
  /// apertura (HU-07) — lee `PersonaCatalogo`, ya poblada por el pull de
  /// catálogo (TE-06), nunca la red directo (invariante 1 de CLAUDE.md). Sin
  /// `Stream`: es una consulta puntual para llenar el dropdown al abrir el
  /// formulario, no una lista que la pantalla necesite mantener reactiva
  /// mientras el modal está abierto (mismo criterio que el resto de este
  /// repositorio, que tampoco expone `Stream` — ver HU-05).
  Future<List<Auxiliar>> auxiliaresDisponibles() async {
    final consulta = _db.select(_db.personaCatalogo)
      ..where((t) => t.rol.equals('auxiliar') & t.activo.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.nombre)]);
    final filas = await consulta.get();
    return filas.map((f) => Auxiliar(id: f.id, nombre: f.nombre)).toList();
  }

  Future<bool> _existeTrabajo(String trabajoUuidCliente) async {
    final fila =
        await (_db.select(_db.trabajoLocal)
              ..where((t) => t.uuidCliente.equals(trabajoUuidCliente)))
            .getSingleOrNull();
    return fila != null;
  }

  Future<int> _contarSesionesDeTrabajo(String trabajoUuidCliente) async {
    final cantidad = countAll();
    final consulta = _db.selectOnly(_db.sesionLocal)
      ..addColumns([cantidad])
      ..where(_db.sesionLocal.trabajoUuidCliente.equals(trabajoUuidCliente));
    final fila = await consulta.getSingle();
    return fila.read(cantidad) ?? 0;
  }

  /// Ver el mismo comentario en `TrabajoRepository._proximaSecuenciaGlobal`
  /// — se duplica a propósito (CLAUDE.md: no crear una abstracción
  /// compartida nueva solo para esto).
  Future<int> _proximaSecuenciaGlobal() async {
    final maximo = _db.colaSync.secuencia.max();
    final fila = await (_db.selectOnly(
      _db.colaSync,
    )..addColumns([maximo])).getSingle();
    return (fila.read(maximo) ?? 0) + 1;
  }

  Sesion _sesionDesdeFila(SesionLocalData fila) {
    return Sesion(
      uuidCliente: fila.uuidCliente,
      trabajoUuidCliente: fila.trabajoUuidCliente,
      secuencia: fila.secuencia,
      pilotoId: fila.pilotoId,
      auxiliarId: fila.auxiliarId,
      dronId: fila.dronId,
      hectareasDeclaradas: fila.hectareasDeclaradas,
      hectareaInicialAcumulada: fila.hectareaInicialAcumulada,
      inicio: fila.inicio,
      estado: fila.estado == EstadoSesionLocal.abierta
          ? EstadoSesion.abierta
          : EstadoSesion.cerrada,
      fin: fila.fin,
      motivoCierre: fila.motivoCierre,
      hectareasDeclaradasCierre: fila.hectareasDeclaradasCierre,
      litrosConsumidos: fila.litrosConsumidos,
      uuidClienteCierre: fila.uuidClienteCierre,
    );
  }
}
