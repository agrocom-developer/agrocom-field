import 'package:decimal/decimal.dart';

/// Eventos de `SesionBloc` — HU-05, Etapa 3/4 (ADR 0005 de `agrocom-api`,
/// regla 4: sesión es un flujo con secuencia y transiciones, no una pantalla
/// lista/detalle).
sealed class SesionEvento {
  const SesionEvento();
}

final class SesionAbrirSolicitada extends SesionEvento {
  const SesionAbrirSolicitada({
    this.hectareasDeclaradas,
    required this.vientoKmh,
    required this.temperaturaC,
    required this.humedadPct,
    this.observacionAgronomo,
    this.firmaObservacion,
  });

  final Decimal? hectareasDeclaradas;

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
    required this.hectareasDeclaradas,
    this.litrosConsumidos,
  });

  final String motivoCierre;
  final Decimal hectareasDeclaradas;
  final Decimal? litrosConsumidos;
}
