import '../domain/trabajo.dart';

/// Estado de `TrabajoCubit` — pantalla simple de apertura, alcanza con
/// inicial/cargando/exitoso/error (ver HU-05: "Etapa 3, solo Cubits de
/// presentación" — criterio: sin transiciones explícitas de máquina de
/// estados, solo carga de un recurso).
sealed class TrabajoEstado {
  const TrabajoEstado();
}

final class TrabajoInicial extends TrabajoEstado {
  const TrabajoInicial();
}

final class TrabajoCargando extends TrabajoEstado {
  const TrabajoCargando();
}

final class TrabajoExitoso extends TrabajoEstado {
  const TrabajoExitoso(this.trabajo);

  final Trabajo trabajo;

  @override
  bool operator ==(Object other) =>
      other is TrabajoExitoso && other.trabajo == trabajo;

  @override
  int get hashCode => trabajo.hashCode;
}

final class TrabajoError extends TrabajoEstado {
  const TrabajoError(this.mensaje);

  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is TrabajoError && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}
