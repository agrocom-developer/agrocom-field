import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tema_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Un proceso que se envía al servidor (aceptar una oferta, confirmar un
/// cierre) pasa por estos cuatro momentos — nunca "cargando" a secas.
enum EstadoEnvioCampo { inactivo, enviando, exito, error }

/// Botón primario con el ciclo de vida de un envío al servidor:
/// inactivo → enviando (indicador) → éxito (tilde) o error (ícono de alerta,
/// vuelve solo a inactivo para reintentar). La transición entre caras es un
/// `AnimatedSwitcher` corto (`MovimientoCampo.rapida`) con una háptica sutil
/// en éxito y error — nunca el único aviso: el texto y el ícono cambian
/// igual con movimiento reducido.
///
/// Quien lo usa controla [estado] desde el bloc; este widget no decide solo
/// cuándo un envío terminó, solo cómo se ve cada momento.
class BotonEnvioCampo extends StatefulWidget {
  const BotonEnvioCampo({
    required this.texto,
    required this.onPressed,
    required this.estado,
    this.textoEnviando,
    this.textoExito,
    this.textoError,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final EstadoEnvioCampo estado;
  final String? textoEnviando;
  final String? textoExito;
  final String? textoError;

  @override
  State<BotonEnvioCampo> createState() => _BotonEnvioCampoState();
}

class _BotonEnvioCampoState extends State<BotonEnvioCampo> {
  @override
  void didUpdateWidget(BotonEnvioCampo anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.estado == widget.estado) return;
    if (widget.estado == EstadoEnvioCampo.exito) {
      HapticaCampo.confirmacion();
    } else if (widget.estado == EstadoEnvioCampo.error) {
      HapticaCampo.alerta();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final radio = Theme.of(context).extension<TemaCampo>()?.radioPill ?? 999;
    final bloqueado =
        widget.estado == EstadoEnvioCampo.enviando ||
        widget.estado == EstadoEnvioCampo.exito;
    final esError = widget.estado == EstadoEnvioCampo.error;

    final (icono, texto) = switch (widget.estado) {
      EstadoEnvioCampo.inactivo => (null, widget.texto),
      EstadoEnvioCampo.enviando => (
        null,
        widget.textoEnviando ?? l10n.componentesEnviando,
      ),
      EstadoEnvioCampo.exito => (
        Icons.check_rounded,
        widget.textoExito ?? l10n.botonEnvioExito,
      ),
      EstadoEnvioCampo.error => (
        Icons.refresh_rounded,
        widget.textoError ?? l10n.botonEnvioError,
      ),
    };

    // En error no se pinta el relleno entero de rojo: ese par de contraste
    // no está medido para un botón lleno en los tres modos (el rol `error`
    // es de texto/ícono, no de relleno — sistema-visual.md §2). Se usa el
    // mismo lenguaje que `BotonSecundarioCampo`: contorno y texto en rojo.
    final colorTexto = esError ? paleta.error : paleta.sobreAcento;
    final fondo = esError ? Colors.transparent : paleta.acento;
    final contenido = AnimatedSwitcher(
      duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
      switchInCurve: MovimientoCampo.entrada,
      switchOutCurve: MovimientoCampo.salida,
      transitionBuilder: (child, animacion) => FadeTransition(
        opacity: animacion,
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(animacion),
          child: child,
        ),
      ),
      child: _Contenido(
        key: ValueKey(widget.estado),
        estado: widget.estado,
        icono: icono,
        texto: texto,
        colorTexto: colorTexto,
      ),
    );

    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ObjetivoTactilCampo.guantes,
        ),
        child: esError
            ? OutlinedButton(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: paleta.error,
                  side: BorderSide(color: paleta.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radio),
                  ),
                ),
                child: contenido,
              )
            : FilledButton(
                onPressed: bloqueado ? null : widget.onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: fondo,
                  disabledBackgroundColor: fondo.withValues(alpha: 0.65),
                  foregroundColor: paleta.sobreAcento,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radio),
                  ),
                ),
                child: contenido,
              ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.estado,
    required this.icono,
    required this.texto,
    required this.colorTexto,
    super.key,
  });

  final EstadoEnvioCampo estado;
  final IconData? icono;
  final String texto;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    if (estado == EstadoEnvioCampo.enviando) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: colorTexto,
            ),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Flexible(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TipografiaCampo.etiqueta.copyWith(
                fontSize: 16,
                color: colorTexto,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icono != null) ...[
          Icon(icono, size: 20, color: colorTexto),
          const SizedBox(width: EspaciadoCampo.s),
        ],
        Flexible(
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colorTexto,
            ),
          ),
        ),
      ],
    );
  }
}
