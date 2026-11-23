import 'package:flutter/material.dart';

import '../../ui/tokens_campo.dart';

/// Entrada de un bloque de contenido: opacidad y un desplazamiento corto
/// hacia arriba, una sola vez al montarse. [orden] retrasa el arranque para
/// que los bloques de una pantalla entren en cascada (jerarquía de lectura).
///
/// Solo anima `opacity` y `transform` (sistema visual, §7). Con movimiento
/// reducido el contenido aparece ya en su lugar.
class AparicionMarketplace extends StatefulWidget {
  const AparicionMarketplace({required this.child, this.orden = 0, super.key});

  final Widget child;
  final int orden;

  /// Retraso entre un bloque y el siguiente.
  static const Duration paso = Duration(milliseconds: 50);

  /// A partir de este orden los bloques entran juntos: la cascada completa
  /// no supera los 300 ms de espera.
  static const int ordenMaximo = 6;

  @override
  State<AparicionMarketplace> createState() => _AparicionMarketplaceState();
}

class _AparicionMarketplaceState extends State<AparicionMarketplace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _avance;
  bool _iniciada = false;

  @override
  void initState() {
    super.initState();
    final orden = widget.orden.clamp(0, AparicionMarketplace.ordenMaximo);
    final espera = AparicionMarketplace.paso * orden;
    final total = espera + MovimientoCampo.media;
    _controlador = AnimationController(vsync: this, duration: total);
    _avance = CurvedAnimation(
      parent: _controlador,
      curve: Interval(
        espera.inMilliseconds / total.inMilliseconds,
        1,
        curve: MovimientoCampo.entrada,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MovimientoCampo.reducido(context)) {
      _controlador.value = 1;
    } else {
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
      opacity: _avance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_avance),
        child: widget.child,
      ),
    );
  }
}
