import 'package:decimal/decimal.dart';

/// Estado LOCAL de un trabajo — deliberadamente un enum propio de dominio
/// puro, distinto de `EstadoTrabajoLocal` (`nucleo/db/tablas/trabajo_local.dart`):
/// ese archivo importa `drift`, y `domain/` no puede acoplarse a
/// infraestructura (ADR 0005 de `agrocom-api`). `TrabajoRepository` es quien
/// mapea entre los dos. Mismo criterio que `EstadoSesion`.
enum EstadoTrabajo { abierto, cerrado }

/// Trabajo abierto por el piloto sobre una orden/lote del catálogo —
/// apertura (`AperturaTrabajo`) y, cuando corresponde, cierre
/// (`CierreTrabajo`, HU-09) en la misma entidad, espejo de `TrabajoLocal`
/// (ver esa tabla para el porqué de no separarlos en dos).
///
/// Entidad Dart pura: sin `drift` ni `dio`, testeable sin emulador (ADR
/// 0005 de `agrocom-api`).
class Trabajo {
  const Trabajo({
    required this.uuidCliente,
    required this.ordenId,
    required this.loteId,
    required this.nroAplicacion,
    required this.hectareasDeclaradas,
    required this.inicio,
    this.estado = EstadoTrabajo.abierto,
    this.fin,
    this.litrosSobrante,
    this.evidenciaImagenCampoUuidCliente,
    this.uuidClienteCierre,
  });

  /// Identidad generada en el dispositivo, nunca en el servidor (invariante
  /// 2 de CLAUDE.md).
  final String uuidCliente;

  /// `OrdenCatalogo.id`.
  final int ordenId;

  /// `OrdenCatalogo.loteId`, copiado a la apertura.
  final int loteId;

  /// `OrdenCatalogo.nroAplicacion`, copiado a la apertura.
  final int nroAplicacion;

  /// Nunca `double` (invariante 9 de CLAUDE.md). Nota: `trabajos.hectareas_declaradas`
  /// es un valor DERIVADO del lado servidor (suma de sesiones) — este campo
  /// es el que el dispositivo declaró a la apertura, nunca algo que el
  /// cierre del trabajo (HU-09) vuelva a tocar.
  final Decimal hectareasDeclaradas;

  final DateTime inicio;

  final EstadoTrabajo estado;

  /// Momento de cierre. `null` mientras [estado] sea [EstadoTrabajo.abierto].
  final DateTime? fin;

  /// Litros sobrantes al cerrar, opcional (espec §7.2). Nunca `double`
  /// (invariante 9 de CLAUDE.md).
  final Decimal? litrosSobrante;

  /// `uuid_cliente` de una evidencia `imagen_campo` ya subida — REQUERIDA
  /// para cerrar ("sin captura no cierra"). `null` mientras [estado] sea
  /// [EstadoTrabajo.abierto].
  final String? evidenciaImagenCampoUuidCliente;

  /// `uuid_cliente` del EVENTO de cierre — distinto de [uuidCliente] (el de
  /// apertura).
  final String? uuidClienteCierre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trabajo &&
          other.uuidCliente == uuidCliente &&
          other.ordenId == ordenId &&
          other.loteId == loteId &&
          other.nroAplicacion == nroAplicacion &&
          other.hectareasDeclaradas == hectareasDeclaradas &&
          other.inicio == inicio &&
          other.estado == estado &&
          other.fin == fin &&
          other.litrosSobrante == litrosSobrante &&
          other.evidenciaImagenCampoUuidCliente ==
              evidenciaImagenCampoUuidCliente &&
          other.uuidClienteCierre == uuidClienteCierre);

  @override
  int get hashCode => Object.hashAll([
    uuidCliente,
    ordenId,
    loteId,
    nroAplicacion,
    hectareasDeclaradas,
    inicio,
    estado,
    fin,
    litrosSobrante,
    evidenciaImagenCampoUuidCliente,
    uuidClienteCierre,
  ]);
}
