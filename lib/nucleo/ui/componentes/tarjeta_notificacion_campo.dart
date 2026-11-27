import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Canal de una notificación — mismo vocabulario en la bandeja de la app y
/// en el canal real de `flutter_local_notifications` que arma la capa de
/// notificaciones (`NotificacionesRemotas`, hoy un puerto nulo mientras
/// Firebase está apagado). Este archivo solo define el estilo — ícono,
/// color semántico y nombre del canal — para que ambos lados se vean igual
/// cuando se conecten.
enum CanalNotificacionCampo {
  ofertas,
  servicio,
  sincronizacion,
  sistema;

  /// Nombre visible del canal nativo (Android crea un canal por tipo, ADR
  /// de `CLAUDE.md` «Notificaciones con canal propio por tipo»): quien
  /// registre el canal real usa este mismo texto, para que no diverja del
  /// que ve el usuario dentro de la app.
  String nombre(AppLocalizations l10n) => switch (this) {
    ofertas => l10n.notificacionCanalOfertas,
    servicio => l10n.notificacionCanalServicio,
    sincronizacion => l10n.notificacionCanalSincronizacion,
    sistema => l10n.notificacionCanalSistema,
  };
}

/// Estilo visual de un [CanalNotificacionCampo]: ícono y color semántico de
/// [PaletaCampo]. Lo usa tanto [TarjetaNotificacionCampo] (bandeja dentro de
/// la app) como la configuración del canal nativo (nombre e ícono pequeño),
/// para que una oferta nueva se vea igual en los dos lugares.
@immutable
class EstiloCanalNotificacionCampo {
  const EstiloCanalNotificacionCampo({
    required this.icono,
    required this.color,
  });

  final IconData icono;

  /// Selector de rol sobre [PaletaCampo] — no un color fijo, para que
  /// funcione igual en claro, oscuro y campo.
  final Color Function(PaletaCampo paleta) color;

  static const _estilos = {
    CanalNotificacionCampo.ofertas: EstiloCanalNotificacionCampo(
      icono: Icons.local_offer_rounded,
      color: _acento,
    ),
    CanalNotificacionCampo.servicio: EstiloCanalNotificacionCampo(
      icono: Icons.flight_takeoff_rounded,
      color: _info,
    ),
    CanalNotificacionCampo.sincronizacion: EstiloCanalNotificacionCampo(
      icono: Icons.sync_rounded,
      color: _textoSecundario,
    ),
    CanalNotificacionCampo.sistema: EstiloCanalNotificacionCampo(
      icono: Icons.campaign_rounded,
      color: _alerta,
    ),
  };

  static Color _acento(PaletaCampo p) => p.acentoTexto;
  static Color _info(PaletaCampo p) => p.info;
  static Color _textoSecundario(PaletaCampo p) => p.textoSecundario;
  static Color _alerta(PaletaCampo p) => p.alerta;

  static EstiloCanalNotificacionCampo de(CanalNotificacionCampo canal) =>
      _estilos[canal]!;
}

/// Tarjeta de una notificación en la bandeja dentro de la app: ícono del
/// canal, título, cuerpo (máximo dos líneas), cuándo llegó y un punto de
/// "no leída". El golpecito la abre; nunca lleva una acción destructiva
/// directa (eso vive en [MenuAccionesCampo] si hace falta).
class TarjetaNotificacionCampo extends StatelessWidget {
  const TarjetaNotificacionCampo({
    required this.canal,
    required this.titulo,
    required this.cuerpo,
    required this.cuando,
    this.leida = true,
    this.onTap,
    super.key,
  });

  final CanalNotificacionCampo canal;
  final String titulo;
  final String cuerpo;

  /// Ya formateado ("Hace 5 min", "Ayer 14:30") — esta tarjeta no calcula
  /// tiempo relativo.
  final String cuando;
  final bool leida;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final estilo = EstiloCanalNotificacionCampo.de(canal);
    final color = estilo.color(paleta);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EspaciadoCampo.l,
            vertical: EspaciadoCampo.m,
          ),
          color: leida ? null : color.withValues(alpha: 0.06),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(RadioCampo.media),
                ),
                child: Icon(estilo.icono, size: 20, color: color),
              ),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: TipografiaCampo.tituloTarjeta.copyWith(
                        color: paleta.texto,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cuerpo,
                      style: TipografiaCampo.cuerpoSecundario.copyWith(
                        color: paleta.textoSecundario,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      cuando,
                      style: TipografiaCampo.datoMono.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              if (!leida) ...[
                const SizedBox(width: EspaciadoCampo.s),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
