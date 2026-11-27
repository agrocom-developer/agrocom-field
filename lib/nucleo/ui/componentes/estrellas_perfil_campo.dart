import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';
import 'estrella_campo.dart';

/// Las cinco estrellas de oro del perfil, con media estrella y el promedio
/// al lado («5,0»). Va sobre la cabecera verde ([CabeceraPerfilCampo]); al
/// tocarla se abre la pantalla de calificaciones. Quien no tiene
/// calificaciones todavía pasa 5,0.
///
/// Brillan una sola vez al aparecer y otra al tocarlas: un destello de luz
/// cruza las estrellas de izquierda a derecha (~900 ms). No hay bucle, y con
/// «reducir movimiento» no hay destello.
class EstrellasPerfilCampo extends StatefulWidget {
  const EstrellasPerfilCampo({
    required this.valor,
    this.total,
    this.onTap,
    super.key,
  }) : assert(valor >= 0 && valor <= 5);

  final double valor;

  /// Cuántas calificaciones respaldan el promedio; solo lo lee el lector de
  /// pantalla.
  final int? total;

  final VoidCallback? onTap;

  static const double tamanoEstrella = 30;

  /// Duración del destello.
  static const Duration duracionBrillo = Duration(milliseconds: 900);

  @override
  State<EstrellasPerfilCampo> createState() => _EstrellasPerfilCampoState();
}

class _EstrellasPerfilCampoState extends State<EstrellasPerfilCampo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(
    vsync: this,
    duration: EstrellasPerfilCampo.duracionBrillo,
  );
  bool _inicial = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicial) {
      _inicial = false;
      _destellar();
    }
  }

  void _destellar() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _brillo.forward(from: 0);
  }

  @override
  void dispose() {
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final valor = widget.valor;
    final numero = valor.toStringAsFixed(1).replaceAll('.', ',');
    final estrellas = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          EstrellaCampo(
            tamano: EstrellasPerfilCampo.tamanoEstrella,
            llena: valor >= i - 0.25,
            media: valor < i - 0.25 && valor >= i - 0.75,
          ),
      ],
    );
    final contenido = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ObjetivoTactilCampo.minimo),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _brillo,
            child: estrellas,
            builder: (context, hijo) {
              final t = _brillo.value;
              // Sin animación en curso, las estrellas se pintan tal cual.
              if (t == 0 || t == 1) return hijo!;
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (r) {
                  // La franja de luz va de fuera por la izquierda a fuera por
                  // la derecha.
                  final centro = -0.25 + 1.5 * t;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Color(0x00FFFFFF),
                      Color(0xE6FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [
                      (centro - 0.18).clamp(0.0, 1.0),
                      centro.clamp(0.0, 1.0),
                      (centro + 0.18).clamp(0.0, 1.0),
                    ],
                  ).createShader(r);
                },
                child: hijo,
              );
            },
          ),
          const SizedBox(width: EspaciadoCampo.s),
          Text(
            numero,
            style: texto.titleMedium?.copyWith(
              color: paleta.sobreCabecera,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: widget.onTap != null,
      onTap: widget.onTap,
      label: AppLocalizations.of(context).perfilUxCalificacionSemantica(numero),
      excludeSemantics: true,
      child: widget.onTap == null
          ? contenido
          : InkWell(
              onTap: () {
                _destellar();
                widget.onTap!();
              },
              borderRadius: BorderRadius.circular(RadioCampo.chip),
              child: contenido,
            ),
    );
  }
}
