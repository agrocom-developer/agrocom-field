import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';

/// Texto visible de cada motivo de problema, desde los ARB.
extension TextosMotivoProblema on MotivoProblema {
  String etiquetaL10n(AppLocalizations l10n) => switch (this) {
    MotivoProblema.coberturaIncompleta =>
      l10n.problemaMotivoCoberturaIncompleta,
    MotivoProblema.malaAplicacion => l10n.problemaMotivoMalaAplicacion,
    MotivoProblema.danoCultivos => l10n.problemaMotivoDanoCultivos,
    MotivoProblema.productoDistinto => l10n.problemaMotivoProductoDistinto,
    MotivoProblema.equipoAusente => l10n.problemaMotivoEquipoAusente,
    MotivoProblema.evidenciaFaltante => l10n.problemaMotivoEvidenciaFaltante,
    MotivoProblema.cobroIndebido => l10n.problemaMotivoCobroIndebido,
    MotivoProblema.tratoInadecuado => l10n.problemaMotivoTratoInadecuado,
  };

  String ayudaL10n(AppLocalizations l10n) => switch (this) {
    MotivoProblema.coberturaIncompleta =>
      l10n.problemaMotivoCoberturaIncompletaAyuda,
    MotivoProblema.malaAplicacion => l10n.problemaMotivoMalaAplicacionAyuda,
    MotivoProblema.danoCultivos => l10n.problemaMotivoDanoCultivosAyuda,
    MotivoProblema.productoDistinto => l10n.problemaMotivoProductoDistintoAyuda,
    MotivoProblema.equipoAusente => l10n.problemaMotivoEquipoAusenteAyuda,
    MotivoProblema.evidenciaFaltante =>
      l10n.problemaMotivoEvidenciaFaltanteAyuda,
    MotivoProblema.cobroIndebido => l10n.problemaMotivoCobroIndebidoAyuda,
    MotivoProblema.tratoInadecuado => l10n.problemaMotivoTratoInadecuadoAyuda,
  };
}
