import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../domain/cuenta_proveedor.dart';
import 'documentos_cubit.dart';

/// Textos de los enums de la cuenta, con `switch` exhaustivo (ADR 0022).
extension TextosTipoDocumento on TipoDocumentoProveedor {
  String etiqueta(AppLocalizations l10n) => switch (this) {
    TipoDocumentoProveedor.identidad => l10n.documentosTipoIdentidad,
    TipoDocumentoProveedor.licenciaPiloto => l10n.documentosTipoLicenciaPiloto,
    TipoDocumentoProveedor.habilitacionDron =>
      l10n.documentosTipoHabilitacionDron,
    TipoDocumentoProveedor.seguroResponsabilidad =>
      l10n.documentosTipoSeguroResponsabilidad,
    TipoDocumentoProveedor.registroDron => l10n.documentosTipoRegistroDron,
    TipoDocumentoProveedor.certificadoFumigacion =>
      l10n.documentosTipoCertificadoFumigacion,
    TipoDocumentoProveedor.antecedentes => l10n.documentosTipoAntecedentes,
    TipoDocumentoProveedor.otro => l10n.documentosTipoOtro,
  };
}

extension TextosEtapaDocumento on EtapaDocumento {
  String etiqueta(AppLocalizations l10n) => switch (this) {
    EtapaDocumento.faltante => l10n.documentosEtapaFaltante,
    EtapaDocumento.subiendo => l10n.documentosEtapaSubiendo,
    EtapaDocumento.enRevision => l10n.documentosEtapaEnRevision,
    EtapaDocumento.aprobado => l10n.documentosEtapaAprobado,
    EtapaDocumento.rechazado => l10n.documentosEtapaRechazado,
    EtapaDocumento.vencido => l10n.documentosEtapaVencido,
    EtapaDocumento.errorEnvio => l10n.documentosEtapaError,
  };

  /// Cada estado lleva ícono además de texto: no depende solo del color.
  IconData get icono => switch (this) {
    EtapaDocumento.faltante => Icons.radio_button_unchecked_rounded,
    EtapaDocumento.subiendo => Icons.cloud_upload_outlined,
    EtapaDocumento.enRevision => Icons.hourglass_top_rounded,
    EtapaDocumento.aprobado => Icons.check_circle_outline_rounded,
    EtapaDocumento.rechazado => Icons.cancel_outlined,
    EtapaDocumento.vencido => Icons.event_busy_outlined,
    EtapaDocumento.errorEnvio => Icons.cloud_off_rounded,
  };
}

extension TextosDisponibilidad on Disponibilidad {
  String etiqueta(AppLocalizations l10n) => switch (this) {
    Disponibilidad.disponible => l10n.disponibilidadDisponible,
    Disponibilidad.ocupado => l10n.disponibilidadOcupado,
    Disponibilidad.enTrabajo => l10n.disponibilidadEnTrabajo,
  };

  String detalle(AppLocalizations l10n) => switch (this) {
    Disponibilidad.disponible => l10n.disponibilidadDisponibleDetalle,
    Disponibilidad.ocupado => l10n.disponibilidadOcupadoDetalle,
    Disponibilidad.enTrabajo => l10n.disponibilidadEnTrabajoDetalle,
  };

  IconData get icono => switch (this) {
    Disponibilidad.disponible => Icons.notifications_active_outlined,
    Disponibilidad.ocupado => Icons.do_not_disturb_on_outlined,
    Disponibilidad.enTrabajo => Icons.flight_takeoff_outlined,
  };
}
