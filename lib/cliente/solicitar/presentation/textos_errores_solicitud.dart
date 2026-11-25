import '../../../l10n/app_localizations.dart';
import '../domain/reglas_solicitud.dart';
import 'solicitar_estado.dart';

/// Texto de cada fallo de las hectáreas. El `switch` es exhaustivo: un fallo
/// nuevo no compila hasta tener su texto (ADR 0022).
extension TextosErrorHectareas on ErrorHectareas {
  /// [tope] es la superficie del lote guardado, solo para [sobreLote].
  String texto(AppLocalizations l10n, {String tope = ''}) => switch (this) {
    ErrorHectareas.vacio => l10n.solicitarErrorHectareasVacio,
    ErrorHectareas.noEsNumero => l10n.solicitarErrorNoEsNumeroHectareas,
    ErrorHectareas.noPositivo => l10n.solicitarErrorHectareasNoPositivas,
    ErrorHectareas.decimales => l10n.solicitarErrorDosDecimales,
    ErrorHectareas.sobreMaximo => l10n.solicitarErrorHectareasMaximas(
      ReglasSolicitud.hectareasMaximas.toString(),
    ),
    ErrorHectareas.sobreLote => l10n.solicitarErrorHectareasSobreLote(tope),
  };
}

/// Texto de cada fallo del precio.
extension TextosErrorPrecio on ErrorPrecio {
  String texto(AppLocalizations l10n) => switch (this) {
    ErrorPrecio.vacio => l10n.solicitarErrorPrecioVacio,
    ErrorPrecio.noEsNumero => l10n.solicitarErrorNoEsNumeroPrecio,
    ErrorPrecio.noPositivo => l10n.solicitarErrorPrecioNoPositivo,
    ErrorPrecio.decimales => l10n.solicitarErrorDosDecimales,
  };
}

/// Texto de cada paso del flujo.
extension TextosPasoSolicitud on PasoSolicitud {
  String etiquetaL10n(AppLocalizations l10n) => switch (this) {
    PasoSolicitud.lote => l10n.solicitarPasoLote,
    PasoSolicitud.aplicacion => l10n.solicitarPasoAplicacion,
    PasoSolicitud.cuando => l10n.solicitarPasoCuando,
    PasoSolicitud.precio => l10n.solicitarPasoPrecio,
  };
}
