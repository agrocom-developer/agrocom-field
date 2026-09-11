import 'package:decimal/decimal.dart';

/// Trabajo abierto por el piloto sobre una orden/lote del catálogo (espejo
/// de escritura de `AperturaTrabajo`, ver `AperturaTrabajo.php` en
/// `agrocom-api`).
///
/// Entidad Dart pura: sin `drift` ni `dio`, testeable sin emulador (ADR
/// 0005 de `agrocom-api`).
///
/// Sin campo de estado: "trabajo abierto" es "existe la entidad" (mismo
/// criterio que `TrabajoLocal`, ver el comentario en esa tabla) — "cerrar
/// trabajo" es una HU futura, fuera de alcance de HU-05.
class Trabajo {
  const Trabajo({
    required this.uuidCliente,
    required this.ordenId,
    required this.loteId,
    required this.nroAplicacion,
    required this.hectareasDeclaradas,
    required this.inicio,
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

  /// Nunca `double` (invariante 9 de CLAUDE.md).
  final Decimal hectareasDeclaradas;

  final DateTime inicio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trabajo &&
          other.uuidCliente == uuidCliente &&
          other.ordenId == ordenId &&
          other.loteId == loteId &&
          other.nroAplicacion == nroAplicacion &&
          other.hectareasDeclaradas == hectareasDeclaradas &&
          other.inicio == inicio);

  @override
  int get hashCode => Object.hash(
    uuidCliente,
    ordenId,
    loteId,
    nroAplicacion,
    hectareasDeclaradas,
    inicio,
  );
}
