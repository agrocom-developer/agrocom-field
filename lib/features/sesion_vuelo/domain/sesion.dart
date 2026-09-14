import 'package:decimal/decimal.dart';

/// Estado LOCAL de una sesión — deliberadamente un enum propio de dominio
/// puro, distinto de `EstadoSesionLocal`
/// (`nucleo/db/tablas/sesion_local.dart`): ese archivo importa `drift`, y
/// `domain/` no puede acoplarse a infraestructura (ADR 0005 de
/// `agrocom-api`). `SesionRepository` es quien mapea entre los dos.
///
/// No es una transición que la app decida por su cuenta (invariante 7 de
/// CLAUDE.md/`especificacion_funcional_tecnica.md` §5): acá solo describe
/// qué pasó localmente (se abrió, se cerró); la confirmación de servidor es
/// otro concepto (`EstadoSync` de la fila de `ColaSync`), no este.
enum EstadoSesion { abierta, cerrada }

/// Sesión de vuelo dentro de un [Trabajo] — apertura (`AperturaSesion`) y,
/// cuando corresponde, cierre (`CierreSesion`) en la misma entidad, espejo
/// de `SesionLocal` (ver esa tabla para el porqué de no separarlos en dos).
///
/// Entidad Dart pura: sin `drift` ni `dio`, testeable sin emulador (ADR
/// 0005 de `agrocom-api`).
class Sesion {
  const Sesion({
    required this.uuidCliente,
    required this.trabajoUuidCliente,
    required this.secuencia,
    required this.pilotoId,
    required this.hectareasDeclaradas,
    required this.inicio,
    required this.estado,
    this.auxiliarId,
    this.dronId,
    this.hectareaInicialAcumulada,
    this.fin,
    this.motivoCierre,
    this.hectareasDeclaradasCierre,
    this.litrosConsumidos,
    this.uuidClienteCierre,
  });

  /// Identidad DE LA APERTURA, generada en el dispositivo (invariante 2 de
  /// CLAUDE.md).
  final String uuidCliente;

  /// `uuid_cliente` del [Trabajo] que contiene esta sesión.
  final String trabajoUuidCliente;

  /// Orden de apertura dentro de ESE trabajo (empieza en 1).
  final int secuencia;

  /// `persona_id` de quien abre la sesión (invariante 4 de CLAUDE.md).
  final int pilotoId;

  /// HU-07. `null` hasta esa HU.
  final int? auxiliarId;

  /// HU-07. `null` hasta esa HU.
  final int? dronId;

  /// Hectáreas declaradas A LA APERTURA. Nunca `double` (invariante 9 de
  /// CLAUDE.md).
  final Decimal hectareasDeclaradas;

  /// HU-07. `null` hasta esa HU.
  final Decimal? hectareaInicialAcumulada;

  final DateTime inicio;

  final EstadoSesion estado;

  /// Momento de cierre. `null` mientras [estado] sea [EstadoSesion.abierta].
  final DateTime? fin;

  /// Catálogo cerrado del servidor (espec §4.3) — se pasa tal cual, no se
  /// valida acá (ver comentario en `SesionLocal.motivoCierre`).
  final String? motivoCierre;

  /// Hectáreas declaradas AL CIERRE — distinto de [hectareasDeclaradas]
  /// (apertura), nunca se pisan entre sí.
  final Decimal? hectareasDeclaradasCierre;

  /// Opcional incluso al cerrar (ver `CierreSesion::$litrosConsumidos`).
  final Decimal? litrosConsumidos;

  /// `uuid_cliente` del EVENTO de cierre — distinto de [uuidCliente] (el de
  /// apertura).
  final String? uuidClienteCierre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sesion &&
          other.uuidCliente == uuidCliente &&
          other.trabajoUuidCliente == trabajoUuidCliente &&
          other.secuencia == secuencia &&
          other.pilotoId == pilotoId &&
          other.auxiliarId == auxiliarId &&
          other.dronId == dronId &&
          other.hectareasDeclaradas == hectareasDeclaradas &&
          other.hectareaInicialAcumulada == hectareaInicialAcumulada &&
          other.inicio == inicio &&
          other.estado == estado &&
          other.fin == fin &&
          other.motivoCierre == motivoCierre &&
          other.hectareasDeclaradasCierre == hectareasDeclaradasCierre &&
          other.litrosConsumidos == litrosConsumidos &&
          other.uuidClienteCierre == uuidClienteCierre);

  @override
  int get hashCode => Object.hashAll([
    uuidCliente,
    trabajoUuidCliente,
    secuencia,
    pilotoId,
    auxiliarId,
    dronId,
    hectareasDeclaradas,
    hectareaInicialAcumulada,
    inicio,
    estado,
    fin,
    motivoCierre,
    hectareasDeclaradasCierre,
    litrosConsumidos,
    uuidClienteCierre,
  ]);
}
