import 'package:flutter/material.dart';

import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Pantalla de arranque: el logo entra (opacidad y escala desde 0,95), una
/// línea verde se extiende debajo y aparece la propuesta en una frase. La
/// secuencia corre una sola vez y avisa con [alTerminar]; mientras tanto la
/// app lee la sesión guardada.
///
/// Con movimiento reducido todo aparece en su lugar y [alTerminar] se llama
/// en el siguiente cuadro.
class SplashPantalla extends StatefulWidget {
  const SplashPantalla({required this.alTerminar, super.key});

  final VoidCallback alTerminar;

  /// Duración de la secuencia completa.
  static const Duration duracion = Duration(milliseconds: 1400);

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: SplashPantalla.duracion,
  );

  late final Animation<double> _logo = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0, 0.4, curve: MovimientoCampo.entrada),
  );
  late final Animation<double> _linea = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0.3, 0.75, curve: MovimientoCampo.movimiento),
  );
  late final Animation<double> _frase = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0.5, 0.85, curve: MovimientoCampo.entrada),
  );

  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MovimientoCampo.reducido(context)) {
      _controlador.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _terminar());
    } else {
      _controlador.forward().whenComplete(_terminar);
    }
  }

  void _terminar() {
    if (mounted) widget.alTerminar();
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
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EspaciadoCampo.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logo,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1).animate(_logo),
                    child: const LogoAgrocomCampo(ancho: 190, sombra: false),
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                ScaleTransition(
                  scale: _linea,
                  child: Container(
                    width: EspaciadoCampo.xxxl,
                    height: EspaciadoCampo.xs,
                    decoration: BoxDecoration(
                      color: paleta.acento,
                      borderRadius: BorderRadius.circular(EspaciadoCampo.xs),
                    ),
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                FadeTransition(
                  opacity: _frase,
                  child: Text(
                    l10n.accesoFumigacionConDronesPedido,
                    textAlign: TextAlign.center,
                    style: texto.bodyLarge?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
