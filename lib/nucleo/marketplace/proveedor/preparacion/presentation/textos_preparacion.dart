import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../domain/preparacion.dart';

/// Texto e ícono de cada paso. El `switch` es exhaustivo: un paso nuevo no
/// compila hasta tener su texto (ADR 0022).
extension TextosItemPreparacion on ItemPreparacion {
  String titulo(AppLocalizations l10n) => switch (this) {
    ItemPreparacion.baterias => l10n.preparacionBaterias,
    ItemPreparacion.tanque => l10n.preparacionTanque,
    ItemPreparacion.boquillas => l10n.preparacionBoquillas,
    ItemPreparacion.mandoRc => l10n.preparacionMandoRc,
    ItemPreparacion.dron => l10n.preparacionDron,
    ItemPreparacion.epp => l10n.preparacionEpp,
    ItemPreparacion.documentos => l10n.preparacionDocumentos,
    ItemPreparacion.clima => l10n.preparacionClima,
    ItemPreparacion.pronostico => l10n.preparacionPronostico,
  };

  String detalle(AppLocalizations l10n) => switch (this) {
    ItemPreparacion.baterias => l10n.preparacionBateriasDetalle,
    ItemPreparacion.tanque => l10n.preparacionTanqueDetalle,
    ItemPreparacion.boquillas => l10n.preparacionBoquillasDetalle,
    ItemPreparacion.mandoRc => l10n.preparacionMandoRcDetalle,
    ItemPreparacion.dron => l10n.preparacionDronDetalle,
    ItemPreparacion.epp => l10n.preparacionEppDetalle,
    ItemPreparacion.documentos => l10n.preparacionDocumentosDetalle,
    ItemPreparacion.clima => l10n.preparacionClimaDetalle,
    ItemPreparacion.pronostico => l10n.preparacionPronosticoDetalle,
  };

  IconData get icono => switch (this) {
    ItemPreparacion.baterias => Icons.battery_charging_full_rounded,
    ItemPreparacion.tanque => Icons.water_drop_outlined,
    ItemPreparacion.boquillas => Icons.shower_outlined,
    ItemPreparacion.mandoRc => Icons.settings_remote_outlined,
    ItemPreparacion.dron => Icons.flight_outlined,
    ItemPreparacion.epp => Icons.health_and_safety_outlined,
    ItemPreparacion.documentos => Icons.badge_outlined,
    ItemPreparacion.clima => Icons.air_rounded,
    ItemPreparacion.pronostico => Icons.wb_sunny_outlined,
  };
}
