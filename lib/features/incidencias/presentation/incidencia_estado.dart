import '../domain/incidencia.dart';

/// Estado de `IncidenciaCubit` — un caso de uso puntual (registrar), no un
/// flujo con transiciones múltiples como `SesionEstado`: inicial, enviando,
/// exitosa, error.
sealed class IncidenciaEstado {
  const IncidenciaEstado();
}

final class IncidenciaInicial extends IncidenciaEstado {
  const IncidenciaInicial();
}

final class IncidenciaEnviando extends IncidenciaEstado {
  const IncidenciaEnviando();
}

final class IncidenciaExitosa extends IncidenciaEstado {
  const IncidenciaExitosa(this.incidencia);

  final Incidencia incidencia;

  @override
  bool operator ==(Object other) =>
      other is IncidenciaExitosa && other.incidencia == incidencia;

  @override
  int get hashCode => incidencia.hashCode;
}

final class IncidenciaError extends IncidenciaEstado {
  const IncidenciaError(this.mensaje);

  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is IncidenciaError && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}
