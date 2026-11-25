import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paleta_campo.dart';

/// Escala de espaciado en múltiplos de 4. Ninguna pantalla usa un número
/// suelto fuera de esta escala.
abstract final class EspaciadoCampo {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Margen lateral de pantalla: 16 en teléfono, 24 en tableta.
  static double margenLateral(double ancho) => ancho >= 600 ? xl : l;
}

/// Radios de esquina compartidos por tarjetas, avisos y miniaturas.
abstract final class RadioCampo {
  /// Superficies medianas: avisos, banners, miniaturas y bloques de contenido.
  static const double media = 14;
}

/// Tamaño mínimo de un objetivo táctil: 48 en la app general (Material),
/// 56 con guantes (flavor piloto).
abstract final class ObjetivoTactilCampo {
  static const double minimo = 48;
  static const double guantes = 56;
}

/// Elevación: en claro se expresa con sombra suave; en oscuro, con una
/// superficie más clara (la sombra no se ve sobre fondo oscuro).
abstract final class ElevacionCampo {
  /// Niveles 0 (plano), 1 (tarjeta), 2 (oferta/menú), 3 (modal).
  static List<BoxShadow> sombras(PaletaCampo paleta, int nivel) {
    if (paleta.brillo == Brightness.dark || nivel <= 0) return const [];
    const colorBase = Color(0xFF15210F);
    return switch (nivel) {
      1 => [
        BoxShadow(
          color: colorBase.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      2 => [
        BoxShadow(
          color: colorBase.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      _ => [
        BoxShadow(
          color: colorBase.withValues(alpha: 0.16),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
    };
  }

  /// Superficie correspondiente al nivel (en oscuro sube de claridad).
  static Color superficie(PaletaCampo paleta, int nivel) =>
      nivel >= 2 ? paleta.superficieElevada : paleta.superficie;
}

/// Tokens de movimiento. Una interacción de interfaz dura menos de 300 ms;
/// solo las entradas de pantalla y de hoja modal llegan a [lenta].
abstract final class MovimientoCampo {
  /// Respuesta a un toque (escala del botón, ripple).
  static const Duration toque = Duration(milliseconds: 100);
  static const Duration rapida = Duration(milliseconds: 160);
  static const Duration media = Duration(milliseconds: 240);

  /// Entrada de pantalla u hoja modal.
  static const Duration lenta = Duration(milliseconds: 320);

  /// Ciclo del esqueleto de carga.
  static const Duration esqueleto = Duration(milliseconds: 1400);

  /// Elemento que aparece o entra: arranca rápido, frena suave.
  static const Curve entrada = Cubic(0.23, 1, 0.32, 1);

  /// Elemento que sale: acelera, sin rebote.
  static const Curve salida = Cubic(0.4, 0, 1, 1);

  /// Elemento que ya está en pantalla y se mueve o cambia de tamaño.
  static const Curve movimiento = Cubic(0.77, 0, 0.175, 1);

  /// Escala de un botón mientras se presiona.
  static const double escalaPresionado = 0.97;

  /// El usuario pidió reducir el movimiento (iOS "Reducir movimiento",
  /// Android "Quitar animaciones").
  static bool reducido(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [normal] salvo con movimiento reducido, donde el cambio es instantáneo.
  /// La opacidad puede seguir animándose: reducir no es eliminar el
  /// feedback (ver docs/diseno/sistema-visual.md).
  static Duration duracion(BuildContext context, Duration normal) =>
      reducido(context) ? Duration.zero : normal;
}

/// Háptica con vocabulario del producto. Nunca se usa como único canal de
/// feedback: siempre acompaña un cambio visible.
abstract final class HapticaCampo {
  /// Cambio de selección (estrella, pestaña, segmento).
  static Future<void> seleccion() => HapticFeedback.selectionClick();

  /// Acción confirmada (aceptar servicio, enviar calificación).
  static Future<void> confirmacion() => HapticFeedback.mediumImpact();

  /// Algo que exige atención (oferta por vencer, error).
  static Future<void> alerta() => HapticFeedback.heavyImpact();
}

/// Clases de ancho de pantalla (alineadas con las window size classes de
/// Material 3). Un iPad vertical es [medio]; horizontal, [expandido].
enum ClasePantallaCampo {
  compacto,
  medio,
  expandido;

  static ClasePantallaCampo deAncho(double ancho) {
    if (ancho < 600) return compacto;
    if (ancho < 840) return medio;
    return expandido;
  }

  static ClasePantallaCampo of(BuildContext context) =>
      deAncho(MediaQuery.sizeOf(context).width);
}
