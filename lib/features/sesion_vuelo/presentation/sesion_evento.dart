import 'package:decimal/decimal.dart';

/// Eventos de `SesionBloc` — HU-05, Etapa 3/4 (ADR 0005 de `agrocom-api`,
/// regla 4: sesión es un flujo con secuencia y transiciones, no una pantalla
/// lista/detalle).
sealed class SesionEvento {
  const SesionEvento();
}

final class SesionAbrirSolicitada extends SesionEvento {
  const SesionAbrirSolicitada({
    this.auxiliarId,
    this.dronId,
    this.hectareasDeclaradas,
    this.hectareaInicialAcumulada,
    required this.vientoKmh,
    required this.temperaturaC,
    required this.humedadPct,
    this.observacionAgronomo,
    this.firmaObservacion,
  });

  /// HU-07 (relevo de piloto) — los tres opcionales: `null` cuando no hay
  /// auxiliar asignado, no se conoce el id de servidor del dron, o no es un
  /// relevo (primera sesión del lote, sin acumulado previo).
  final int? auxiliarId;
  final int? dronId;
  final Decimal? hectareasDeclaradas;
  final Decimal? hectareaInicialAcumulada;

  /// Condiciones al abrir sesión (HU-06) — obligatorias, ver
  /// `docs/api/openapi.yaml` de `agrocom-api`, `RegistroSync` tipo
  /// `condiciones`.
  final Decimal vientoKmh;
  final Decimal temperaturaC;
  final Decimal humedadPct;

  /// Obligatorias juntas cuando alguna medición cae fuera de rango — ver
  /// `reglas_condiciones.dart`.
  final String? observacionAgronomo;
  final String? firmaObservacion;
}

final class SesionCerrarSolicitada extends SesionEvento {
  const SesionCerrarSolicitada({
    required this.motivoCierre,
    this.hectareasDeclaradas,
    this.hectareaFinalAcumulada,
    this.litrosConsumidos,
  });

  final String motivoCierre;

  /// Ingreso directo — obligatorio salvo que la sesión activa tenga
  /// `hectareaInicialAcumulada` no nulo, caso en el que el formulario pide
  /// [hectareaFinalAcumulada] en su lugar (HU-07, control de doble conteo:
  /// ver `SesionRepository.cerrarSesion`).
  final Decimal? hectareasDeclaradas;
  final Decimal? hectareaFinalAcumulada;
  final Decimal? litrosConsumidos;
}
