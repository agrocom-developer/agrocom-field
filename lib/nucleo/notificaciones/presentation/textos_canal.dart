import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/canal_aviso.dart';

/// Nombre, descripción e ícono de cada canal. El `switch` es exhaustivo: un
/// canal nuevo no compila hasta tener su texto (ADR 0022).
extension TextosCanalAviso on CanalAviso {
  String nombre(AppLocalizations l10n) => switch (this) {
    CanalAviso.nuevasSolicitudes => l10n.avisosCanalNuevasSolicitudes,
    CanalAviso.ofertas => l10n.avisosCanalOfertas,
    CanalAviso.mensajes => l10n.avisosCanalMensajes,
    CanalAviso.ejecucion => l10n.avisosCanalEjecucion,
    CanalAviso.cuenta => l10n.avisosCanalCuenta,
  };

  String descripcion(AppLocalizations l10n) => switch (this) {
    CanalAviso.nuevasSolicitudes => l10n.avisosCanalNuevasSolicitudesDetalle,
    CanalAviso.ofertas => l10n.avisosCanalOfertasDetalle,
    CanalAviso.mensajes => l10n.avisosCanalMensajesDetalle,
    CanalAviso.ejecucion => l10n.avisosCanalEjecucionDetalle,
    CanalAviso.cuenta => l10n.avisosCanalCuentaDetalle,
  };

  IconData get icono => switch (this) {
    CanalAviso.nuevasSolicitudes => Icons.map_outlined,
    CanalAviso.ofertas => Icons.request_quote_outlined,
    CanalAviso.mensajes => Icons.chat_bubble_outline_rounded,
    CanalAviso.ejecucion => Icons.flight_takeoff_rounded,
    CanalAviso.cuenta => Icons.verified_user_outlined,
  };
}
