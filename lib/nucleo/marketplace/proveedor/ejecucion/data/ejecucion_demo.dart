import 'dart:async';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';

import '../../../dominio/dominio.dart';
import '../domain/ejecucion.dart';

/// Ejecución en memoria para el modo demo (ADR 0010): dos servicios del
/// equipo, uno por empezar y otro en marcha. Sin `drift` ni red.
class EjecucionDemo implements EjecucionRepositorio {
  EjecucionDemo({DateTime Function()? reloj, bool vacia = false})
    : _reloj = reloj ?? DateTime.now {
    final hoy = _reloj();
    if (vacia) {
      _servicios = [];
      return;
    }
    _servicios = [
      ServicioEnLote(
        id: 10,
        uuidCliente: 'demo-servicio-10',
        estado: EstadoServicioLote.enEjecucion,
        hectareas: Decimal.parse('80'),
        tipoAplicacion: 'herbicida',
        cultivo: 'Soya',
        producto: 'Glifosato 480 SL, 2 L/ha',
        aportaProducto: 'cliente',
        ventanaDesde: hoy.subtract(const Duration(days: 1)),
        ventanaHasta: hoy.add(const Duration(days: 2)),
        terreno: _terreno,
        referenciasAcceso: 'Camino vecinal a 3 km de la ruta principal.',
        precioHaAcordado: Decimal.parse('115'),
        hectareasEjecutadas: Decimal.parse('51.2'),
        porcentaje: Decimal.parse('64'),
        contactoNombre: 'Agropecuaria San Rafael SRL',
        contactoTelefono: '+591 76543210',
        fotosTotal: 2,
      ),
      ServicioEnLote(
        id: 9,
        uuidCliente: 'demo-servicio-9',
        estado: EstadoServicioLote.adjudicada,
        hectareas: Decimal.parse('120'),
        tipoAplicacion: 'insecticida',
        cultivo: 'Maíz',
        producto: 'Cipermetrina 25 EC, 0,3 L/ha',
        aportaProducto: 'cliente',
        ventanaDesde: hoy.add(const Duration(days: 2)),
        ventanaHasta: hoy.add(const Duration(days: 6)),
        terreno: _terreno,
        precioHaAcordado: Decimal.parse('124'),
        contactoNombre: 'Luis Antelo',
        contactoTelefono: '+591 71234567',
      ),
    ];
  }

  static final _terreno = Lote(
    id: 'demo-terreno',
    nombre: 'Lote Norte',
    zona: 'Warnes',
    cultivo: 'Soya',
    hectareas: Decimal.parse('80'),
    poligono: const [
      GeoPunto(-17.5391, -63.2018),
      GeoPunto(-17.5391, -63.1918),
      GeoPunto(-17.5291, -63.1918),
      GeoPunto(-17.5291, -63.2018),
    ],
  );

  final DateTime Function() _reloj;
  late List<ServicioEnLote> _servicios;
  final _cambios = StreamController<void>.broadcast();

  /// Pendientes simulados: lo marcado «sin señal» en la demo.
  bool enLinea = true;

  void _reemplazar(int id, ServicioEnLote Function(ServicioEnLote) f) {
    _servicios = [for (final s in _servicios) s.id == id ? f(s) : s];
    _cambios.add(null);
  }

  ServicioEnLote? _buscar(int id) {
    for (final s in _servicios) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Stream<List<ServicioEnLote>> observar() async* {
    yield List.unmodifiable(_servicios);
    await for (final _ in _cambios.stream) {
      yield List.unmodifiable(_servicios);
    }
  }

  @override
  Stream<ServicioEnLote?> observarUno(int id) async* {
    yield _buscar(id);
    await for (final _ in _cambios.stream) {
      yield _buscar(id);
    }
  }

  int _pendientes(ServicioEnLote s) => enLinea ? 0 : s.registrosPendientes + 1;

  @override
  Future<void> iniciar(int id) async => _reemplazar(
    id,
    (s) => s.estado == EstadoServicioLote.adjudicada
        ? s.copiarCon(
            estado: EstadoServicioLote.enEjecucion,
            registrosPendientes: _pendientes(s),
          )
        : s,
  );

  @override
  Future<void> marcarAvance(
    int id, {
    Decimal? hectareas,
    Decimal? porcentaje,
    String? nota,
    String? motivoCorreccion,
  }) async => _reemplazar(id, (s) {
    final cien = Decimal.fromInt(100);
    final ha =
        hectareas ??
        (s.hectareas * porcentaje! / cien).toDecimal(
          scaleOnInfinitePrecision: 4,
        );
    final pct =
        porcentaje ??
        (hectareas! * cien / s.hectareas).toDecimal(
          scaleOnInfinitePrecision: 2,
        );
    return s.copiarCon(
      hectareasEjecutadas: ha,
      porcentaje: pct,
      registrosPendientes: _pendientes(s),
    );
  });

  @override
  Future<String> adjuntarFoto(
    int id,
    Uint8List bytes, {
    TipoFotoEjecucion tipo = TipoFotoEjecucion.avance,
  }) async {
    _reemplazar(
      id,
      (s) => s.copiarCon(
        fotosTotal: s.fotosTotal + 1,
        fotosPendientes: enLinea ? s.fotosPendientes : s.fotosPendientes + 1,
      ),
    );
    return 'demo-foto-${_reloj().microsecondsSinceEpoch}';
  }

  @override
  Future<void> finalizar(
    int id, {
    required Decimal hectareasEjecutadas,
    String? nota,
  }) async => _reemplazar(
    id,
    (s) => s.copiarCon(
      estado: EstadoServicioLote.finalizada,
      hectareasEjecutadas: hectareasEjecutadas,
      porcentaje: (hectareasEjecutadas * Decimal.fromInt(100) / s.hectareas)
          .toDecimal(scaleOnInfinitePrecision: 2),
      registrosPendientes: _pendientes(s),
    ),
  );

  @override
  Future<void> limpiarAlCerrarSesion() async {}

  @override
  Future<void> sincronizarAhora() async {
    if (!enLinea) return;
    _servicios = [
      for (final s in _servicios)
        s.copiarCon(registrosPendientes: 0, fotosPendientes: 0),
    ];
    _cambios.add(null);
  }
}

class ServicioUbicacionDemo implements ServicioUbicacion {
  ServicioUbicacionDemo({this.permiso = PermisoUbicacion.denegado});

  PermisoUbicacion permiso;

  @override
  Future<PermisoUbicacion> estado() async => permiso;

  @override
  Future<PermisoUbicacion> pedir() async =>
      permiso = PermisoUbicacion.concedido;

  @override
  Future<GeoPunto?> actual() async => permiso == PermisoUbicacion.concedido
      ? const GeoPunto(-17.5341, -63.1968)
      : null;
}

class UbicacionDemo implements UbicacionRepositorio {
  final publicadas = <GeoPunto>[];

  @override
  Future<void> publicar(
    int solicitudId,
    GeoPunto punto, {
    double? precisionM,
  }) async => publicadas.add(punto);
}
