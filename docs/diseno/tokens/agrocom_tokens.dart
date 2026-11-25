// Agrocom · Industrial AgTech — ThemeExtension para Flutter
// Generado desde el diseño. Ajustar nombres al patrón de tema existente del proyecto.
import 'package:flutter/material.dart';

@immutable
class AgColors extends ThemeExtension<AgColors> {
  const AgColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.graphite,
    required this.onGraphite,
    required this.amber,
    required this.onAmber,
    required this.amberContainer,
    required this.onAmberContainer,
    required this.paper,
    required this.paper2,
    required this.paperFold,
    required this.onPaper,
    required this.text,
    required this.text2,
    required this.border,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.success,
    required this.warning,
  });
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color graphite;
  final Color onGraphite;
  final Color amber;
  final Color onAmber;
  final Color amberContainer;
  final Color onAmberContainer;
  final Color paper;
  final Color paper2;
  final Color paperFold;
  final Color onPaper;
  final Color text;
  final Color text2;
  final Color border;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color success;
  final Color warning;

  static const light = AgColors(
    bg: Color(0xFFF3F5F1),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE9EEE7),
    primary: Color(0xFF347A36),
    primaryHover: Color(0xFF28632C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE1EEDD),
    onPrimaryContainer: Color(0xFF22562A),
    graphite: Color(0xFF29343A),
    onGraphite: Color(0xFFFFFFFF),
    amber: Color(0xFFF5A623),
    onAmber: Color(0xFF29343A),
    amberContainer: Color(0xFFFDF0D3),
    onAmberContainer: Color(0xFF7A4B00),
    paper: Color(0xFFFFE680),
    paper2: Color(0xFFFFDA55),
    paperFold: Color(0xFFE8C13E),
    onPaper: Color(0xFF29343A),
    text: Color(0xFF202A2E),
    text2: Color(0xFF68756D),
    border: Color(0xFFDDE4DC),
    info: Color(0xFF2785C7),
    infoContainer: Color(0xFFE2F0FA),
    onInfoContainer: Color(0xFF14577F),
    error: Color(0xFFDC4545),
    errorContainer: Color(0xFFFCE6E6),
    onErrorContainer: Color(0xFFA12727),
    success: Color(0xFF347A36),
    warning: Color(0xFFF5A623),
  );
  static const dark = AgColors(
    bg: Color(0xFF17251C),
    surface: Color(0xFF293832),
    surface2: Color(0xFF34443B),
    primary: Color(0xFF62B66A),
    primaryHover: Color(0xFF79CA80),
    onPrimary: Color(0xFF0F1F12),
    primaryContainer: Color(0xFF2E4A35),
    onPrimaryContainer: Color(0xFFA8DCAC),
    graphite: Color(0xFF34443B),
    onGraphite: Color(0xFFEDF3EC),
    amber: Color(0xFFFFB52E),
    onAmber: Color(0xFF17251C),
    amberContainer: Color(0xFF4A3A17),
    onAmberContainer: Color(0xFFFFD488),
    paper: Color(0xFFF2D56E),
    paper2: Color(0xFFE6C552),
    paperFold: Color(0xFFC9A83A),
    onPaper: Color(0xFF1E2A22),
    text: Color(0xFFEDF3EC),
    text2: Color(0xFFAAB8AC),
    border: Color(0xFF405247),
    info: Color(0xFF50A5D8),
    infoContainer: Color(0xFF1E3A4C),
    onInfoContainer: Color(0xFFA6D4F0),
    error: Color(0xFFFF6868),
    errorContainer: Color(0xFF4A2326),
    onErrorContainer: Color(0xFFFFB4B4),
    success: Color(0xFF62B66A),
    warning: Color(0xFFFFB52E),
  );
  static const campo = AgColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF0F1A13),
    surface2: Color(0xFF1B2A20),
    primary: Color(0xFF8EE08F),
    primaryHover: Color(0xFFA8EBA8),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF1B3A22),
    onPrimaryContainer: Color(0xFFCBF5CB),
    graphite: Color(0xFF1B2A20),
    onGraphite: Color(0xFFFFFFFF),
    amber: Color(0xFFFFC547),
    onAmber: Color(0xFF000000),
    amberContainer: Color(0xFF3A2C00),
    onAmberContainer: Color(0xFFFFE3A3),
    paper: Color(0xFFFFE680),
    paper2: Color(0xFFFFDA55),
    paperFold: Color(0xFFE8C13E),
    onPaper: Color(0xFF000000),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFD7E2D9),
    border: Color(0xFF6B8272),
    info: Color(0xFF8CCBF2),
    infoContainer: Color(0xFF0E2A3B),
    onInfoContainer: Color(0xFFC6E6FA),
    error: Color(0xFFFF8A8A),
    errorContainer: Color(0xFF3D1214),
    onErrorContainer: Color(0xFFFFC9C9),
    success: Color(0xFF8EE08F),
    warning: Color(0xFFFFC547),
  );

  @override
  AgColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? primary,
    Color? primaryHover,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? graphite,
    Color? onGraphite,
    Color? amber,
    Color? onAmber,
    Color? amberContainer,
    Color? onAmberContainer,
    Color? paper,
    Color? paper2,
    Color? paperFold,
    Color? onPaper,
    Color? text,
    Color? text2,
    Color? border,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? error,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? success,
    Color? warning,
  }) => AgColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    primary: primary ?? this.primary,
    primaryHover: primaryHover ?? this.primaryHover,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    graphite: graphite ?? this.graphite,
    onGraphite: onGraphite ?? this.onGraphite,
    amber: amber ?? this.amber,
    onAmber: onAmber ?? this.onAmber,
    amberContainer: amberContainer ?? this.amberContainer,
    onAmberContainer: onAmberContainer ?? this.onAmberContainer,
    paper: paper ?? this.paper,
    paper2: paper2 ?? this.paper2,
    paperFold: paperFold ?? this.paperFold,
    onPaper: onPaper ?? this.onPaper,
    text: text ?? this.text,
    text2: text2 ?? this.text2,
    border: border ?? this.border,
    info: info ?? this.info,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    error: error ?? this.error,
    errorContainer: errorContainer ?? this.errorContainer,
    onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  @override
  AgColors lerp(ThemeExtension<AgColors>? other, double t) {
    if (other is! AgColors) return this;
    return AgColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      graphite: Color.lerp(graphite, other.graphite, t)!,
      onGraphite: Color.lerp(onGraphite, other.onGraphite, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      onAmber: Color.lerp(onAmber, other.onAmber, t)!,
      amberContainer: Color.lerp(amberContainer, other.amberContainer, t)!,
      onAmberContainer: Color.lerp(
        onAmberContainer,
        other.onAmberContainer,
        t,
      )!,
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      paperFold: Color.lerp(paperFold, other.paperFold, t)!,
      onPaper: Color.lerp(onPaper, other.onPaper, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      border: Color.lerp(border, other.border, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AgRadius {
  static const xs = 6.0,
      sm = 12.0,
      md = 16.0,
      lg = 20.0,
      xl = 24.0,
      sheet = 32.0,
      pill = 999.0;
}

class AgSize {
  static const touchMin = 48.0, touchCampo = 72.0, button = 56.0;
}

ColorScheme agScheme(AgColors c, Brightness b) => ColorScheme(
  brightness: b,
  primary: c.primary,
  onPrimary: c.onPrimary,
  primaryContainer: c.primaryContainer,
  onPrimaryContainer: c.onPrimaryContainer,
  secondary: c.graphite,
  onSecondary: c.onGraphite,
  tertiary: c.amber,
  onTertiary: c.onAmber,
  tertiaryContainer: c.amberContainer,
  onTertiaryContainer: c.onAmberContainer,
  error: c.error,
  onError: b == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000),
  errorContainer: c.errorContainer,
  onErrorContainer: c.onErrorContainer,
  surface: c.surface,
  onSurface: c.text,
  onSurfaceVariant: c.text2,
  surfaceContainerHighest: c.surface2,
  outline: c.border,
);
