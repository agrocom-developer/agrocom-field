import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../features/incidencias/data/incidencia_repository.dart';
import '../../features/incidencias/domain/incidencia.dart';
import '../../features/incidencias/domain/tipo_incidencia.dart';
import '../../features/incidencias/presentation/incidencia_cubit.dart';
import '../../features/sesion_vuelo/data/sesion_repository.dart';
import '../../features/sesion_vuelo/data/trabajo_repository.dart';
import '../../features/sesion_vuelo/domain/auxiliar.dart';
import '../../features/sesion_vuelo/domain/reglas_apertura.dart';
import '../../features/sesion_vuelo/domain/reglas_condiciones.dart';
import '../../features/sesion_vuelo/domain/sesion.dart';
import '../../features/sesion_vuelo/domain/trabajo.dart';
import '../../features/sesion_vuelo/domain/trabajo_en_curso.dart';
import '../../features/sesion_vuelo/presentation/fabricas_sesion_vuelo.dart';
import '../../features/sesion_vuelo/presentation/sesion_bloc.dart';
import '../../features/sesion_vuelo/presentation/trabajo_cubit.dart';
import '../../nucleo/auth/persona_operativa_store.dart';
import '../../nucleo/camara/selector_foto.dart';
import '../../nucleo/evidencias/evidencia_repository.dart';
import '../../nucleo/ui/imagenes_campo.dart';
import '../../nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';

/// Sesión de vuelo del perfil demo (`MODO_DEMO`, ADR 0010): la pantalla y
/// los blocs son los de la app; lo que cambia son los repositorios, que
/// guardan en memoria. No abre `drift`, no encola en el outbox ni toca la
/// red. El servicio demo hace de trabajo: su `id` es el `uuid_cliente` del
/// trabajo, y abrir, avanzar y cerrar se reflejan en [AlmacenDemoProveedor].
FabricasSesionVuelo fabricasSesionVueloDemo(
  AlmacenDemoProveedor almacen, {
  Uuid uuid = const Uuid(),
  SelectorFoto? selectorFoto,
}) {
  final sesiones = SesionRepositoryDemo(almacen, uuid: uuid);
  final foto = selectorFoto ?? SelectorFotoDemo();
  final evidencias = _EvidenciaRepositoryDemo(uuid);
  return FabricasSesionVuelo(
    crearSesionBloc: (trabajoUuidCliente) => SesionBloc(
      sesionRepositorio: sesiones,
      personaOperativaStore: const _PersonaOperativaDemo(),
      trabajoUuidCliente: trabajoUuidCliente,
    ),
    crearTrabajoCubit: () => TrabajoCubit(
      _TrabajoRepositoryDemo(almacen, uuid),
      evidenciaRepositorio: evidencias,
      selectorFoto: foto,
    ),
    crearIncidenciaCubit: (sesionUuidCliente) => IncidenciaCubit(
      incidenciaRepositorio: _IncidenciaRepositoryDemo(uuid),
      selectorFoto: foto,
      sesionUuidCliente: sesionUuidCliente,
    ),
  );
}

/// Sesiones en memoria, con las mismas reglas de dominio que el repositorio
/// de `drift` aplica antes de escribir (observación del agrónomo fuera de
/// rango, una sola sesión abierta).
class SesionRepositoryDemo implements SesionRepository {
  SesionRepositoryDemo(this._almacen, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final AlmacenDemoProveedor _almacen;
  final Uuid _uuid;
  final _sesiones = <Sesion>[];

  Sesion? _abierta() {
    for (final sesion in _sesiones) {
      if (sesion.estado == EstadoSesion.abierta) return sesion;
    }
    return null;
  }

  @override
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
    verificarObservacionSiFueraDeRango(
      fueraDeRango: condicionesFueraDeRango(
        vientoKmh: vientoKmh,
        temperaturaC: temperaturaC,
        humedadPct: humedadPct,
        limites: LimitesCondiciones.porDefecto(),
      ),
      observacionAgronomo: observacionAgronomo,
      firmaObservacion: firmaObservacion,
    );
    final sesion = Sesion(
      uuidCliente: _uuid.v4(),
      trabajoUuidCliente: trabajoUuidCliente,
      secuencia:
          _sesiones
              .where((s) => s.trabajoUuidCliente == trabajoUuidCliente)
              .length +
          1,
      pilotoId: pilotoId,
      auxiliarId: auxiliarId,
      dronId: dronId,
      hectareasDeclaradas: hectareasDeclaradas ?? Decimal.zero,
      hectareaInicialAcumulada: hectareaInicialAcumulada,
      inicio: inicio,
      estado: EstadoSesion.abierta,
    );
    _sesiones.add(sesion);
    _almacen.iniciarServicio(trabajoUuidCliente);
    return sesion;
  }

  @override
  Future<Sesion> cerrarSesion({
    required String sesionUuidCliente,
    required DateTime fin,
    required String motivoCierre,
    Decimal? hectareasDeclaradas,
    Decimal? hectareaFinalAcumulada,
    Decimal? litrosConsumidos,
  }) async {
    final indice = _sesiones.indexWhere(
      (s) => s.uuidCliente == sesionUuidCliente,
    );
    final previa = _sesiones[indice];
    final inicial = previa.hectareaInicialAcumulada;
    final cubiertas = inicial != null && hectareaFinalAcumulada != null
        ? hectareaFinalAcumulada - inicial
        : hectareasDeclaradas ?? Decimal.zero;
    final cerrada = Sesion(
      uuidCliente: previa.uuidCliente,
      trabajoUuidCliente: previa.trabajoUuidCliente,
      secuencia: previa.secuencia,
      pilotoId: previa.pilotoId,
      auxiliarId: previa.auxiliarId,
      dronId: previa.dronId,
      hectareasDeclaradas: previa.hectareasDeclaradas,
      hectareaInicialAcumulada: inicial,
      inicio: previa.inicio,
      estado: EstadoSesion.cerrada,
      fin: fin,
      motivoCierre: motivoCierre,
      hectareasDeclaradasCierre: cubiertas,
      litrosConsumidos: litrosConsumidos,
      uuidClienteCierre: _uuid.v4(),
    );
    _sesiones[indice] = cerrada;
    _almacen.registrarAvance(previa.trabajoUuidCliente, cubiertas);
    return cerrada;
  }

  @override
  Future<LimitesCondiciones> limitesCondiciones(
    String trabajoUuidCliente,
  ) async => LimitesCondiciones.porDefecto();

  @override
  Future<Sesion?> sesionAbiertaDeTrabajo(String trabajoUuidCliente) async {
    final abierta = _abierta();
    return abierta?.trabajoUuidCliente == trabajoUuidCliente ? abierta : null;
  }

  @override
  Future<RestriccionApertura> restriccionAperturaDeTrabajo(
    String trabajoUuidCliente,
  ) async => restriccionApertura(haySesionAbierta: _abierta() != null);

  @override
  Future<List<Auxiliar>> auxiliaresDisponibles() async => const [];
}

class _TrabajoRepositoryDemo implements TrabajoRepository {
  _TrabajoRepositoryDemo(this._almacen, this._uuid);

  final AlmacenDemoProveedor _almacen;
  final Uuid _uuid;

  @override
  Stream<TrabajoEnCurso?> enCurso() => Stream.value(null);

  @override
  Future<Trabajo> abrirTrabajo({
    required int ordenId,
    required int loteId,
    required int nroAplicacion,
    Decimal? hectareasDeclaradas,
    required DateTime inicio,
  }) => throw UnsupportedError('El perfil demo abre el trabajo al aceptar');

  @override
  Future<Trabajo> abrirTrabajoAsignado({
    required String uuidCliente,
    required int ordenId,
    required int loteId,
    required int nroAplicacion,
    required DateTime inicio,
  }) => throw UnsupportedError('El perfil demo abre el trabajo al aceptar');

  @override
  Future<Trabajo> cerrarTrabajo({
    required String trabajoUuidCliente,
    required DateTime fin,
    Decimal? litrosSobrante,
    required String evidenciaImagenCampoUuidCliente,
  }) async {
    _almacen.completarServicio(trabajoUuidCliente);
    return Trabajo(
      uuidCliente: trabajoUuidCliente,
      ordenId: 0,
      loteId: 0,
      nroAplicacion: 1,
      hectareasDeclaradas: Decimal.zero,
      inicio: fin,
      estado: EstadoTrabajo.cerrado,
      fin: fin,
      litrosSobrante: litrosSobrante,
      evidenciaImagenCampoUuidCliente: evidenciaImagenCampoUuidCliente,
      uuidClienteCierre: _uuid.v4(),
    );
  }
}

class _IncidenciaRepositoryDemo implements IncidenciaRepository {
  _IncidenciaRepositoryDemo(this._uuid);

  final Uuid _uuid;

  @override
  Future<Incidencia> registrarIncidencia({
    required String sesionUuidCliente,
    required TipoIncidencia tipo,
    String? descripcion,
    required DateTime hora,
    required Uint8List bytesFoto,
  }) async => Incidencia(
    uuidCliente: _uuid.v4(),
    sesionUuidCliente: sesionUuidCliente,
    tipo: tipo,
    descripcion: descripcion,
    hora: hora,
    evidenciaFotoUuidCliente: _uuid.v4(),
  );
}

class _EvidenciaRepositoryDemo implements EvidenciaRepository {
  _EvidenciaRepositoryDemo(this._uuid);

  final Uuid _uuid;

  @override
  Future<String> capturarEvidencia({
    required Uint8List bytesOriginales,
    required String tipo,
    required DateTime fecha,
  }) async => _uuid.v4();
}

class _PersonaOperativaDemo implements PersonaOperativaStore {
  const _PersonaOperativaDemo();

  @override
  Future<int?> leerPersonaId() async => 1;

  @override
  Future<void> guardarPersonaId(int? personaId) async {}

  @override
  Future<void> borrarPersonaId() async {}
}

/// «Cámara» del perfil demo: devuelve una foto empaquetada con la app en
/// vez de abrir la cámara del dispositivo.
class SelectorFotoDemo implements SelectorFoto {
  @override
  Future<Uint8List?> tomarFoto() async {
    final datos = await rootBundle.load(ImagenesCampo.dronPulverizando);
    return datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes);
  }
}
