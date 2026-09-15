/// Rutas de los assets visuales del modo "campo" (ADR 0008) — un solo lugar
/// para el nombre de cada archivo, así una pantalla no repite el string y un
/// rename del asset se corrige acá y en `pubspec.yaml`, no en cada uso.
///
/// Procedencia y peso de cada foto: `assets/imagenes/FUENTES.md`. Son
/// fondos decorativos — nunca evidencia de un trabajo real (invariante 8 de
/// `CLAUDE.md`: la evidencia siempre la captura el piloto/auxiliar).
abstract final class ImagenesCampo {
  /// Logo completo (isotipo + wordmark AGROCOM) — es lo que nombra a la app
  /// en pantalla; ninguna pantalla escribe el nombre además del logo.
  static const String logo = 'assets/imagenes/agrocom_logo.png';

  /// Agras pulverizando sobre un cultivo verde al atardecer, apaisada —
  /// fondo pleno del login.
  static const String dronPulverizando =
      'assets/imagenes/fondo_dron_pulverizando.jpg';

  /// Agras pulverizando con sierras de fondo, vertical — fondo pleno del
  /// onboarding (la única en formato de celular, sin recorte agresivo).
  static const String dronPulverizandoVertical =
      'assets/imagenes/fondo_dron_pulverizando_vertical.jpg';

  /// Agras T50 pulverizando a contraluz dorado, primer plano — franja
  /// superior de inicio.
  static const String dronAgrasT50 = 'assets/imagenes/fondo_dron_agras_t50.jpg';

  /// Agras en vuelo estacionario sobre agua, cielo gris — franja superior de
  /// una pantalla técnica (vinculación de dispositivo).
  static const String dronSobreAgua =
      'assets/imagenes/fondo_dron_sobre_agua.jpg';

  /// Equipo en tierra: dron, generador, baterías y RC — reservada para las
  /// pantallas de equipos/baterías del auxiliar (HU-80).
  static const String equipoDron = 'assets/imagenes/fondo_equipo_dron.jpg';
}
