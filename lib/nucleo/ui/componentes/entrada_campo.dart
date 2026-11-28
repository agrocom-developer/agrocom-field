import 'package:flutter/material.dart';

import '../tokens_campo.dart';

/// Entrada de un bloque: fundido y subida corta (12 dp). Con
/// [escalonar] cada hijo entra 40 ms después del anterior, para que la
/// pantalla «se arme» en vez de aparecer de golpe. Con «reducir movimiento»
/// el contenido aparece sin animar.
class EntradaCampo extends StatefulWidget {
  const EntradaCampo({required this.child, this.indice = 0, super.key});

  final Widget child;

  /// Posición en la secuencia; define el retraso (40 ms por posición, hasta 8).
  final int indice;

  /// Envuelve cada elemento de [hijos] con su retraso escalonado. Los
  /// espaciadores (`SizedBox`) no se animan.
  static List<Widget> escalonar(List<Widget> hijos) {
    var i = 0;
    return [
      for (final h in hijos)
        if (h is SizedBox) h else EntradaCampo(indice: i++, child: h),
    ];
  }

  @override
  State<EntradaCampo> createState() => _EntradaCampoState();
}

class _EntradaCampoState extends State<EntradaCampo>
    with SingleTickerProviderStateMixin {
  static const _retraso = 40;
  static const _base = 240;
  static const _maximoIndice = 8;

  late final AnimationController _controlador;
  late final Animation<double> _progreso;

  @override
  void initState() {
    super.initState();
    final i = widget.indice.clamp(0, _maximoIndice);
    final total = _base + i * _retraso;
    _controlador = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _progreso = CurvedAnimation(
      parent: _controlador,
      curve: Interval(
        (i * _retraso) / total,
        1,
        curve: MovimientoCampo.entrada,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.value = 1;
    } else if (!_controlador.isAnimating && _controlador.value == 0) {
      _controlador.forward();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progreso,
      child: AnimatedBuilder(
        animation: _progreso,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - _progreso.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
