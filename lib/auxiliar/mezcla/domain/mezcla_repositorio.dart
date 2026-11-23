import 'package:decimal/decimal.dart';

/// Una carga de caldo preparada por el auxiliar. Nace en el dispositivo con
/// su `uuidCliente` (invariante 2 de `CLAUDE.md`); el repositorio real la
/// inserta en `drift` y la encola en el outbox en una sola transacción.
class RegistroMezcla {
  const RegistroMezcla({
    required this.uuidCliente,
    required this.producto,
    required this.litros,
    required this.numeroTanque,
    required this.registradoEn,
    this.sincronizado = false,
  });

  final String uuidCliente;
  final String producto;

  /// Litros de caldo, decimal exacto (ADR 0002).
  final Decimal litros;
  final int numeroTanque;
  final DateTime registradoEn;

  /// Si el servidor ya lo confirmó (estado de sincronización a la vista).
  final bool sincronizado;
}

abstract interface class MezclaRepositorio {
  Stream<List<RegistroMezcla>> observar();

  /// Registra al instante, sin esperar al servidor.
  Future<void> registrar({required String producto, required Decimal litros});
}
