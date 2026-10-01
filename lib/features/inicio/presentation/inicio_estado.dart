import '../domain/trabajo_asignado.dart';

/// Estado de `InicioCubit`: arranca `InicioCargando` y de ahí alterna entre
/// `InicioConTrabajo` y `InicioSinTrabajo` según cada emisión del stream —
/// el vacío es un estado explícito, nunca un trabajo inventado.
sealed class InicioEstado {
  const InicioEstado();
}

final class InicioCargando extends InicioEstado {
  const InicioCargando();
}

final class InicioSinTrabajo extends InicioEstado {
  const InicioSinTrabajo();
}

final class InicioConTrabajo extends InicioEstado {
  const InicioConTrabajo(this.trabajo);

  final TrabajoAsignado trabajo;

  @override
  bool operator ==(Object other) =>
      other is InicioConTrabajo && other.trabajo == trabajo;

  @override
  int get hashCode => trabajo.hashCode;
}
