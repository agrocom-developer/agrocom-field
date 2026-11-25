import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Marcador de carga con la forma del contenido que viene — evita el salto
/// de layout al llegar los datos. Brilla con un barrido suave; con
/// "reducir movimiento" queda estático.
///
/// Se usa donde sí hay espera de red: el flavor cliente (online-first) y la
/// superficie del proveedor (ofertas, perfil, drones). En el lote (offline) los datos salen de `drift` y no hay
/// esqueleto: la pantalla ya tiene contenido.
class EsqueletoCampo extends StatefulWidget {
  const EsqueletoCampo({this.ancho, this.alto = 16, this.radio = 8, super.key});

  /// Línea de texto de [lineas] líneas, la última más corta.
  static Widget texto({int lineas = 3, double alto = 14}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lineas; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == lineas - 1 ? 0 : 8),
            child: LayoutBuilder(
              builder: (context, c) => EsqueletoCampo(
                ancho: i == lineas - 1 && lineas > 1 ? c.maxWidth * 0.6 : null,
                alto: alto,
              ),
            ),
          ),
      ],
    );
  }

  final double? ancho;
  final double alto;
  final double radio;

  @override
  State<EsqueletoCampo> createState() => _EsqueletoCampoState();
}

class _EsqueletoCampoState extends State<EsqueletoCampo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: MovimientoCampo.esqueleto,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MovimientoCampo.reducido(context)) {
      _controlador.stop();
    } else if (!_controlador.isAnimating) {
      _controlador.repeat();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final base = paleta.texto.withValues(alpha: 0.08);
    final brillo = paleta.texto.withValues(alpha: 0.16);
    return Semantics(
      label: l10n.componentesCargando,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controlador,
        builder: (context, _) {
          final t = _controlador.value;
          return Container(
            width: widget.ancho,
            height: widget.alto,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radio),
              gradient: _controlador.isAnimating
                  ? LinearGradient(
                      begin: Alignment(-1.5 + 3 * t, 0),
                      end: Alignment(-0.5 + 3 * t, 0),
                      colors: [base, brillo, base],
                    )
                  : null,
              color: _controlador.isAnimating ? null : base,
            ),
          );
        },
      ),
    );
  }
}
