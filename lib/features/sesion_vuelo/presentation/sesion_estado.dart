import '../domain/sesion.dart';

/// Estado de `SesionBloc` — modeliza el ciclo de vida de una sesión:
/// inicial (sin sesión abierta), abriendo, activa (en vuelo), cerrando,
/// cerrada (con datos de cierre), error. No hay una transición de máquina de
/// estados del lado del servidor (eso es autoridad de `agrocom-api`, ver
/// invariante 7 de CLAUDE.md) — acá solo se modeliza la progresión local:
/// propuesta → propuesta confirmada localmente → confirmada por servidor.
sealed class SesionEstado {
  const SesionEstado();
}

final class SesionInicial extends SesionEstado {
  const SesionInicial();
}

final class SesionAbriendo extends SesionEstado {
  const SesionAbriendo();
}

/// Sesión activa (recién abierta o en curso de vuelo) — el estado "activa"
/// persiste desde la apertura hasta el cierre local, no es reactivo a
/// cambios en la base (SesionRepository no expone Stream — ver alcance de
/// HU-05, Etapa 3).
final class SesionActiva extends SesionEstado {
  const SesionActiva(this.sesion);

  final Sesion sesion;

  @override
  bool operator ==(Object other) =>
      other is SesionActiva && other.sesion == sesion;

  @override
  int get hashCode => sesion.hashCode;
}

final class SesionCerrando extends SesionEstado {
  const SesionCerrando();
}

/// Sesión cerrada — los campos de cierre están llenos.
final class SesionCerrada extends SesionEstado {
  const SesionCerrada(this.sesion);

  final Sesion sesion;

  @override
  bool operator ==(Object other) =>
      other is SesionCerrada && other.sesion == sesion;

  @override
  int get hashCode => sesion.hashCode;
}

final class SesionError extends SesionEstado {
  const SesionError(this.mensaje);

  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is SesionError && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}
