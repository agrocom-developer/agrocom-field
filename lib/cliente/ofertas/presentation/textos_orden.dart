import '../../../l10n/app_localizations.dart';
import '../domain/comparador_ofertas.dart';

/// Texto visible de cada orden de las ofertas. El `switch` es exhaustivo: un
/// orden nuevo no compila hasta tener su texto (ADR 0022).
extension TextosOrdenOfertas on OrdenOfertas {
  String etiquetaL10n(AppLocalizations l10n) => switch (this) {
    OrdenOfertas.recomendado => l10n.ofertasOrdenRecomendado,
    OrdenOfertas.precio => l10n.ofertasOrdenPrecio,
    OrdenOfertas.calificacion => l10n.ofertasOrdenCalificacion,
    OrdenOfertas.reciente => l10n.ofertasOrdenReciente,
  };
}
