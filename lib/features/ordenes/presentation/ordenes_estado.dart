import 'package:flutter/foundation.dart' show listEquals;

import '../domain/orden_vigente.dart';

/// Estado de `OrdenesCubit`: arranca `OrdenesCargando` (todavía no llegó la
/// primera emisión del stream del repositorio) y de ahí en más alterna
/// entre `OrdenesLista` y `OrdenesVacia` según el contenido de cada
/// emisión — nunca vuelve a `OrdenesCargando`.
sealed class OrdenesEstado {
  const OrdenesEstado();
}

final class OrdenesCargando extends OrdenesEstado {
  const OrdenesCargando();
}

final class OrdenesVacia extends OrdenesEstado {
  const OrdenesVacia();
}

final class OrdenesLista extends OrdenesEstado {
  const OrdenesLista(this.ordenes);

  final List<OrdenVigente> ordenes;

  @override
  bool operator ==(Object other) =>
      other is OrdenesLista && listEquals(other.ordenes, ordenes);

  @override
  int get hashCode => Object.hashAll(ordenes);
}
