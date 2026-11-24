import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/reglas_solicitud.dart';

/// Pasos del flujo, uno por pantalla.
enum PasoSolicitud {
  lote('Lote'),
  aplicacion('Aplicación'),
  cuando('Cuándo'),
  precio('Precio');

  const PasoSolicitud(this.etiqueta);
  final String etiqueta;
}

/// Cómo indica el cliente el terreno: uno ya registrado o un contorno nuevo.
enum ModoLote { guardado, dibujo }

enum CargaSolicitud { cargando, lista, error }

/// Por qué no salió la solicitud.
enum FalloEnvio { sinConexion, rechazado, desconocido }

const _sinCambio = Object();

/// Estado completo del formulario de solicitud. Vive en el cubit, no en los
/// widgets: un fallo de envío o un cambio de paso nunca pierde lo escrito.
@immutable
class SolicitarEstado {
  const SolicitarEstado({
    required this.claveIdempotencia,
    this.carga = CargaSolicitud.cargando,
    this.lotes = const [],
    this.productos = const [],
    this.cultivos = const [],
    this.fechas = const [],
    this.paso = PasoSolicitud.lote,
    this.avanza = true,
    this.modoLote = ModoLote.guardado,
    this.loteGuardado,
    this.vertices = const [],
    this.hectareasTexto = '',
    this.cultivo,
    this.producto,
    this.fecha,
    this.errorFecha,
    this.accesos = '',
    this.observaciones = '',
    this.precioTexto = '',
    this.enviando = false,
    this.falloEnvio,
    this.mensajeRechazo,
    this.solicitud,
  });

  /// Nace al abrir el formulario y viaja en cada reintento.
  final String claveIdempotencia;
  final CargaSolicitud carga;
  final List<Lote> lotes;
  final List<String> productos;
  final List<String> cultivos;

  /// Fechas que se pueden elegir (anticipación mínima ya aplicada).
  final List<DateTime> fechas;
  final PasoSolicitud paso;

  /// Sentido del último cambio de paso, para la transición.
  final bool avanza;
  final ModoLote modoLote;
  final Lote? loteGuardado;

  /// Esquinas del contorno dibujado, en el orden en que se marcaron.
  final List<GeoPunto> vertices;

  /// Lo que hay escrito en el campo de hectáreas, tal cual.
  final String hectareasTexto;
  final String? cultivo;
  final String? producto;
  final DateTime? fecha;
  final String? errorFecha;

  /// Cómo se llega al lote, para los pilotos que lo evalúan.
  final String accesos;
  final String observaciones;

  /// Lo que hay escrito en el campo de precio por hectárea, tal cual.
  final String precioTexto;
  final bool enviando;
  final FalloEnvio? falloEnvio;

  /// Lo que dijo el servidor cuando rechazó la solicitud.
  final String? mensajeRechazo;

  /// La solicitud publicada; con valor, el flujo terminó.
  final Solicitud? solicitud;

  bool get contornoCerrado => vertices.length >= 3;

  /// Superficie que sale del lote elegido o del contorno dibujado.
  Decimal? get hectareasCalculadas => switch (modoLote) {
    ModoLote.guardado => loteGuardado?.hectareas,
    ModoLote.dibujo => contornoCerrado ? hectareasDePoligono(vertices) : null,
  };

  String? get errorHectareas {
    final base = ReglasSolicitud.errorDeHectareas(hectareasTexto);
    if (base != null) return base;
    // Un terreno ya registrado limita la superficie que se puede pedir.
    final tope = modoLote == ModoLote.guardado ? loteGuardado?.hectareas : null;
    final pedidas = ReglasSolicitud.parsearHectareas(hectareasTexto);
    if (tope != null && pedidas != null && pedidas > tope) {
      return 'El lote tiene $tope ha: no puedes pedir más.';
    }
    return null;
  }

  /// Superficie a fumigar, o `null` si lo escrito no es válido.
  Decimal? get hectareas => errorHectareas == null
      ? ReglasSolicitud.parsearHectareas(hectareasTexto)
      : null;

  /// El terreno de la solicitud: el guardado, o uno nuevo con el contorno.
  Lote? get lote => switch (modoLote) {
    ModoLote.guardado => loteGuardado,
    ModoLote.dibujo =>
      contornoCerrado
          ? Lote(
              id: 'lote-$claveIdempotencia',
              nombre: 'Lote nuevo',
              zona: 'Contorno dibujado',
              cultivo: cultivo ?? '',
              hectareas: hectareas ?? hectareasDePoligono(vertices),
              poligono: vertices,
            )
          : null,
  };

  /// El precio por hectárea escrito, o `null` si no sirve.
  Decimal? get precio => ReglasSolicitud.errorDePrecio(precioTexto) == null
      ? ReglasSolicitud.parsearPrecio(precioTexto)
      : null;

  /// El precio escrito dice algo incorrecto; `null` mientras el campo está
  /// vacío (no se regaña antes de escribir).
  String? get errorPrecio => precioTexto.trim().isEmpty
      ? null
      : ReglasSolicitud.errorDePrecio(precioTexto);

  /// Total estimado con el precio propuesto.
  Decimal? get total {
    final ha = hectareas;
    final p = precio;
    return ha == null || p == null ? null : ha * p;
  }

  bool get puedeAvanzar => switch (paso) {
    PasoSolicitud.lote => lote != null,
    PasoSolicitud.aplicacion =>
      hectareas != null && cultivo != null && producto != null,
    PasoSolicitud.cuando => fecha != null,
    PasoSolicitud.precio => precio != null && !enviando,
  };

  SolicitarEstado copiarCon({
    CargaSolicitud? carga,
    List<Lote>? lotes,
    List<String>? productos,
    List<String>? cultivos,
    List<DateTime>? fechas,
    PasoSolicitud? paso,
    bool? avanza,
    ModoLote? modoLote,
    Object? loteGuardado = _sinCambio,
    List<GeoPunto>? vertices,
    String? hectareasTexto,
    Object? cultivo = _sinCambio,
    String? producto,
    Object? fecha = _sinCambio,
    Object? errorFecha = _sinCambio,
    String? accesos,
    String? observaciones,
    String? precioTexto,
    bool? enviando,
    Object? falloEnvio = _sinCambio,
    Object? mensajeRechazo = _sinCambio,
    Solicitud? solicitud,
  }) => SolicitarEstado(
    claveIdempotencia: claveIdempotencia,
    carga: carga ?? this.carga,
    lotes: lotes ?? this.lotes,
    productos: productos ?? this.productos,
    cultivos: cultivos ?? this.cultivos,
    fechas: fechas ?? this.fechas,
    paso: paso ?? this.paso,
    avanza: avanza ?? this.avanza,
    modoLote: modoLote ?? this.modoLote,
    loteGuardado: identical(loteGuardado, _sinCambio)
        ? this.loteGuardado
        : loteGuardado as Lote?,
    vertices: vertices ?? this.vertices,
    hectareasTexto: hectareasTexto ?? this.hectareasTexto,
    cultivo: identical(cultivo, _sinCambio) ? this.cultivo : cultivo as String?,
    producto: producto ?? this.producto,
    fecha: identical(fecha, _sinCambio) ? this.fecha : fecha as DateTime?,
    errorFecha: identical(errorFecha, _sinCambio)
        ? this.errorFecha
        : errorFecha as String?,
    accesos: accesos ?? this.accesos,
    observaciones: observaciones ?? this.observaciones,
    precioTexto: precioTexto ?? this.precioTexto,
    enviando: enviando ?? this.enviando,
    falloEnvio: identical(falloEnvio, _sinCambio)
        ? this.falloEnvio
        : falloEnvio as FalloEnvio?,
    mensajeRechazo: identical(mensajeRechazo, _sinCambio)
        ? this.mensajeRechazo
        : mensajeRechazo as String?,
    solicitud: solicitud ?? this.solicitud,
  );
}
