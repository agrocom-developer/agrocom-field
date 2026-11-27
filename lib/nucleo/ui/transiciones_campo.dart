import 'package:flutter/material.dart';

import 'tokens_campo.dart';

/// Transiciones de página con propósito (150–250 ms): explican un cambio de
/// estado — maestro a detalle, o una pantalla que se apila — y nunca
/// decoran. Respetan "reducir movimiento": con la opción activada, el
/// cambio se reduce a un fundido corto en vez de un desplazamiento.
///
/// Ninguna pantalla construye su propia `PageRouteBuilder`; usa una de
/// estas dos.
abstract final class TransicionesCampo {
  /// Maestro → detalle: la página nueva entra desde la derecha mientras la
  /// actual se desliza un poco hacia la izquierda y se atenúa (misma
  /// sensación que "una capa se abre sobre la otra"). Para navegación
  /// jerárquica normal (lista → detalle, detalle → sub-detalle).
  static Route<T> detalle<T>(WidgetBuilder builder) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, _, _) => builder(context),
      transitionDuration: MovimientoCampo.media,
      reverseTransitionDuration: MovimientoCampo.rapida,
      transitionsBuilder: (context, animacion, animacionSalida, child) {
        if (MovimientoCampo.reducido(context)) {
          return FadeTransition(opacity: animacion, child: child);
        }
        final entra = CurvedAnimation(
          parent: animacion,
          curve: MovimientoCampo.entrada,
        );
        final sale = CurvedAnimation(
          parent: animacionSalida,
          curve: MovimientoCampo.salida,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(sale),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(entra),
            child: FadeTransition(opacity: entra, child: child),
          ),
        );
      },
    );
  }

  /// Pantalla completa que se apila como una hoja modal: entra desde abajo
  /// con un fundido — una confirmación, un formulario de un solo paso, una
  /// vista de pantalla completa que no es parte de la pila normal (p. ej.
  /// el mapa expandido).
  static Route<T> modal<T>(WidgetBuilder builder) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, _) => builder(context),
      transitionDuration: MovimientoCampo.lenta,
      reverseTransitionDuration: MovimientoCampo.media,
      transitionsBuilder: (context, animacion, _, child) {
        if (MovimientoCampo.reducido(context)) {
          return FadeTransition(opacity: animacion, child: child);
        }
        final curva = CurvedAnimation(
          parent: animacion,
          curve: MovimientoCampo.entrada,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curva),
          child: FadeTransition(opacity: curva, child: child),
        );
      },
    );
  }
}
