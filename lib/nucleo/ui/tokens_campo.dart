import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colores_campo.dart';
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

/// Radios de esquina (tokens.json: radius). Ninguna pantalla declara un radio
/// propio; un test lo vigila (`test/nucleo/ui/tokens_sin_sueltos_test.dart`).
abstract final class RadioCampo {
  /// Marcas pequeñas: esquina de una pastilla de precio, borde de un tab.
  static const double xs = 6;

  /// Chips y filtros.
  static const double chip = 12;

  /// Superficies medianas: avisos, banners, miniaturas y bloques de contenido.
  static const double media = 14;

  /// Campos de texto y burbujas de chat.
  static const double campo = 16;

  /// Tarjetas compactas (miniaturas, collage de fotos).
  static const double tarjetaCompacta = 18;

  /// Tarjetas.
  static const double tarjeta = 24;

  /// Botones principales.
  static const double pildora = 28;

  /// Hoja inferior.
  static const double hoja = 32;

  /// Cápsula completa (insignias, indicadores de estado).
  static const double capsula = 999;
}

/// Tamaño mínimo de un objetivo táctil: 48 en la app general (Material),
/// 56 de alto de botón con guantes y 72 para los controles propios del modo
/// campo (stepper, acciones del lote).
abstract final class ObjetivoTactilCampo {
  static const double minimo = 48;
  static const double guantes = 56;
  static const double campo = 72;
}

/// Elevación: una sola sombra sutil en claro y oscuro (tokens.json: shadow);
/// el modo campo no lleva sombra (se apoya en el borde). Los niveles 2 y 3
/// (oferta, modal) escalan la misma sombra.
abstract final class ElevacionCampo {
  /// Niveles 0 (plano), 1 (tarjeta), 2 (oferta/menú), 3 (modal).
  static List<BoxShadow> sombras(PaletaCampo paleta, int nivel) {
    if (nivel <= 0 || paleta.fondo == ColoresCampo.fondoProfundo) {
      return const [];
    }
    final oscuro = paleta.brillo == Brightness.dark;
    final base = oscuro ? const Color(0xFF000000) : const Color(0xFF202A2E);
    final (a1, a2) = oscuro ? (0.30, 0.25) : (0.06, 0.07);
    final escala = switch (nivel) {
      1 => 1.0,
      2 => 1.6,
      _ => 2.4,
    };
    return [
      BoxShadow(
        color: base.withValues(alpha: a1),
        blurRadius: 2 * escala,
        offset: Offset(0, 1 * escala),
      ),
      BoxShadow(
        color: base.withValues(alpha: (a2 * escala).clamp(0, 0.5)),
        blurRadius: 14 * escala,
        offset: Offset(0, 4 * escala),
      ),
    ];
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
