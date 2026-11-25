import 'dart:typed_data';

import 'package:decimal/decimal.dart';

import '../../../dominio/dominio.dart';

/// Estado de un servicio adjudicado en el lote.
enum EstadoServicioLote {
  adjudicada('Adjudicado', 'Listo para empezar'),
  enEjecucion('En ejecución', 'Sube fotos y marca el avance'),
  finalizada('Finalizado', 'Terminado');

  const EstadoServicioLote(this.etiqueta, this.apoyo);
  final String etiqueta;
  final String apoyo;

  static EstadoServicioLote deCodigo(String codigo) => switch (codigo) {
    'en_ejecucion' => enEjecucion,
    'finalizada' || 'calificada' => finalizada,
    _ => adjudicada,
  };

  String get codigo => switch (this) {
    adjudicada => 'adjudicada',
    enEjecucion => 'en_ejecucion',
    finalizada => 'finalizada',
  };

  bool get activo => this != finalizada;
}

enum TipoFotoEjecucion {
  avance('foto_avance'),
  finalFoto('foto_final');

  const TipoFotoEjecucion(this.codigo);
  final String codigo;
}

/// Un servicio adjudicado al equipo, tal como se ve y se opera en el lote:
/// siempre leído de la base local, nunca de la red (invariante 1).
class ServicioEnLote {
  const ServicioEnLote({
    required this.id,
    required this.uuidCliente,
    required this.estado,
    required this.hectareas,
    this.tipoAplicacion,
    this.cultivo,
    this.producto,
    this.aportaProducto,
    this.ventanaDesde,
    this.ventanaHasta,
    this.urgente = false,
    this.observaciones,
    this.terreno,
    this.accesoDificil = false,
    this.referenciasAcceso,
    this.colindantesSensibles,
    this.precioHaAcordado,
    this.hectareasEjecutadas,
    this.porcentaje,
    this.montoFinal,
    this.contactoNombre,
    this.contactoTelefono,
    this.contactoCargo,
    this.contactoEmpresa,
    this.registrosPendientes = 0,
    this.fotosPendientes = 0,
    this.fotosTotal = 0,
    this.rechazos = 0,
  });

  final int id;
  final String uuidCliente;
  final EstadoServicioLote estado;
  final Decimal hectareas;
  final String? tipoAplicacion;
  final String? cultivo;
  final String? producto;
  final String? aportaProducto;
  final DateTime? ventanaDesde;
  final DateTime? ventanaHasta;
  final bool urgente;
  final String? observaciones;

  /// El terreno con su polígono, si el servidor lo cargó.
  final Lote? terreno;
  final bool accesoDificil;
  final String? referenciasAcceso;
  final String? colindantesSensibles;

  /// El precio de la oferta adjudicada.
  final Decimal? precioHaAcordado;
  final Decimal? hectareasEjecutadas;

  /// Avance de 0 a 100, decimal exacto.
  final Decimal? porcentaje;

  /// Lo congela el servidor al finalizar.
  final Decimal? montoFinal;
  final String? contactoNombre;
  final String? contactoTelefono;

  /// Cargo de la persona de contacto y razón social, si el cliente es una
  /// empresa (`contacto.cargo` y `contacto.empresa` del catálogo).
  final String? contactoCargo;
  final String? contactoEmpresa;

  /// Registros de inicio, avance o cierre todavía sin subir.
  final int registrosPendientes;
  final int fotosPendientes;
  final int fotosTotal;

  /// Registros o fotos que el servidor rechazó y piden atención.
  final int rechazos;

  /// Cuánto queda por subir cuando vuelva la señal.
  int get pendientes => registrosPendientes + fotosPendientes;

  /// Precio a pagar: el que congeló el servidor o, mientras tanto, el
  /// estimado (hectáreas ejecutadas por precio acordado).
  Decimal? get montoAPagar {
    if (montoFinal != null) return montoFinal;
    if (precioHaAcordado == null || hectareasEjecutadas == null) return null;
    return precioHaAcordado! * hectareasEjecutadas!;
  }

  /// `true` si el monto que se muestra lo calculó el servidor.
  bool get montoConfirmado => montoFinal != null;

  /// Avance de 0 a 1 para dibujar la barra.
  double get progreso {
    final p = porcentaje;
    if (p == null) return 0;
    return (p.toDouble() / 100).clamp(0.0, 1.0);
  }

  ServicioEnLote copiarCon({
    EstadoServicioLote? estado,
    Decimal? hectareasEjecutadas,
    Decimal? porcentaje,
    Decimal? montoFinal,
    int? registrosPendientes,
    int? fotosPendientes,
    int? fotosTotal,
  }) => ServicioEnLote(
    id: id,
    uuidCliente: uuidCliente,
    estado: estado ?? this.estado,
    hectareas: hectareas,
    tipoAplicacion: tipoAplicacion,
    cultivo: cultivo,
    producto: producto,
    aportaProducto: aportaProducto,
    ventanaDesde: ventanaDesde,
    ventanaHasta: ventanaHasta,
    urgente: urgente,
    observaciones: observaciones,
    terreno: terreno,
    accesoDificil: accesoDificil,
    referenciasAcceso: referenciasAcceso,
    colindantesSensibles: colindantesSensibles,
    precioHaAcordado: precioHaAcordado,
    hectareasEjecutadas: hectareasEjecutadas ?? this.hectareasEjecutadas,
    porcentaje: porcentaje ?? this.porcentaje,
    montoFinal: montoFinal ?? this.montoFinal,
    contactoNombre: contactoNombre,
    contactoTelefono: contactoTelefono,
    contactoCargo: contactoCargo,
    contactoEmpresa: contactoEmpresa,
    registrosPendientes: registrosPendientes ?? this.registrosPendientes,
    fotosPendientes: fotosPendientes ?? this.fotosPendientes,
    fotosTotal: fotosTotal ?? this.fotosTotal,
    rechazos: rechazos,
  );
}

/// Ejecución de un servicio adjudicado: offline-first. Todo lo que el piloto
/// escribe (inicio, avance, fotos y cierre) se guarda en el dispositivo y se
/// encola en una sola operación; ninguna pantalla espera al servidor
/// (invariantes 1 y 3 de CLAUDE.md).
abstract interface class EjecucionRepositorio {
  /// Servicios adjudicados del equipo, del más urgente al último.
  Stream<List<ServicioEnLote>> observar();

  Stream<ServicioEnLote?> observarUno(int id);

  /// Marca la solicitud `adjudicada` como `en_ejecucion`.
  Future<void> iniciar(int id);

  /// Marca el avance con hectáreas ejecutadas o con un porcentaje.
  Future<void> marcarAvance(
    int id, {
    Decimal? hectareas,
    Decimal? porcentaje,
    String? nota,
    String? motivoCorreccion,
  });

  /// Comprime la foto a menos de 300 KB, la guarda y la encola. Devuelve el
  /// `uuid_cliente` de la foto.
  Future<String> adjuntarFoto(
    int id,
    Uint8List bytes, {
    TipoFotoEjecucion tipo = TipoFotoEjecucion.avance,
  });

  /// Pide el cierre con las hectáreas realmente ejecutadas.
  Future<void> finalizar(
    int id, {
    required Decimal hectareasEjecutadas,
    String? nota,
  });

  /// Intenta subir lo pendiente y bajar el catálogo; sin red no hace nada.
  Future<void> sincronizarAhora();

  /// Al cerrar sesión: descarta lo que el próximo usuario no debe ver y
  /// conserva lo pendiente de subir (la base solo guarda lo que el rol
  /// necesita para operar sin red).
  Future<void> limpiarAlCerrarSesion();
}

/// Qué tan listo está el permiso de ubicación.
enum PermisoUbicacion {
  concedido,
  denegado,
  denegadoParaSiempre,
  servicioApagado,
}

/// Lectura de la ubicación del dispositivo. La app solo la pide cuando hay
/// un servicio en ejecución, con el motivo explicado antes del permiso.
abstract interface class ServicioUbicacion {
  Future<PermisoUbicacion> estado();

  /// Muestra el diálogo del sistema.
  Future<PermisoUbicacion> pedir();

  Future<GeoPunto?> actual();
}

/// Publica la última posición del piloto para que el cliente la vea
/// (`PUT /api/ubicacion`). No va por el outbox: sin red se omite.
abstract interface class UbicacionRepositorio {
  Future<void> publicar(int solicitudId, GeoPunto punto, {double? precisionM});
}
