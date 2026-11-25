import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Acción principal de una pantalla del marketplace: botón verde del tema a
/// ancho completo, con estado de envío. Mientras [cargando] no acepta toques
/// y lo anuncia a los lectores de pantalla.
///
/// Se encoge apenas al presionarlo (`MovimientoCampo.escalaPresionado`);
/// con movimiento reducido no hay escala.
class BotonPrincipalMarketplace extends StatefulWidget {
  const BotonPrincipalMarketplace({
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.icono,
    this.alto = altoMinimo,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  /// Ícono al final del texto (por ejemplo, una flecha de avance).
  final IconData? icono;

  /// Alto mínimo; 56 dp con guantes en piloto.
  final double alto;

  /// Alto mínimo: cuatro pasos por encima del objetivo táctil del cliente.
  static const double altoMinimo =
      ObjetivoTactilCampo.minimo + EspaciadoCampo.xs;

  @override
  State<BotonPrincipalMarketplace> createState() =>
      _BotonPrincipalMarketplaceState();
}

class _BotonPrincipalMarketplaceState extends State<BotonPrincipalMarketplace> {
  bool _presionado = false;

  void _presionar(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final activo = widget.onPressed != null && !widget.cargando;
    final reducido = MovimientoCampo.reducido(context);
    return Semantics(
      label: widget.cargando ? l10n.uiCurso(widget.texto) : null,
      child: Listener(
        onPointerDown: (_) => _presionar(activo),
        onPointerUp: (_) => _presionar(false),
        onPointerCancel: (_) => _presionar(false),
        child: AnimatedScale(
          scale: _presionado && !reducido
              ? MovimientoCampo.escalaPresionado
              : 1,
          duration: MovimientoCampo.toque,
          curve: MovimientoCampo.entrada,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: activo ? widget.onPressed : null,
              style: FilledButton.styleFrom(
                minimumSize: Size(64, widget.alto),
                // Enviando conserva el verde: un botón gris parecería
                // deshabilitado por un error.
                disabledBackgroundColor: widget.cargando
                    ? paleta.acento
                    : paleta.texto.withValues(alpha: 0.12),
                disabledForegroundColor: widget.cargando
                    ? paleta.sobreAcento
                    : paleta.textoSecundario,
              ),
              child: widget.cargando
                  ? ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: paleta.sobreAcento,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.texto,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (widget.icono != null) ...[
                          const SizedBox(width: EspaciadoCampo.s),
                          Icon(widget.icono, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
