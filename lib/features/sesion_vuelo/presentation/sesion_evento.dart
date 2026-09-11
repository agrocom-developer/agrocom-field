import 'package:decimal/decimal.dart';

/// Eventos de `SesionBloc` — HU-05, Etapa 3/4 (ADR 0005 de `agrocom-api`,
/// regla 4: sesión es un flujo con secuencia y transiciones, no una pantalla
/// lista/detalle).
sealed class SesionEvento {
  const SesionEvento();
}

final class SesionAbrirSolicitada extends SesionEvento {
  const SesionAbrirSolicitada({this.hectareasDeclaradas});

  final Decimal? hectareasDeclaradas;
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
