/// URL base de la API que recibió este build. Fallback solo para `flutter
/// run` sin flags — cualquier build real (piloto en campo, staging,
/// producción) SIEMPRE pasa --dart-define-from-file. Ver
/// docs/decisiones/0004-configuracion-entorno-dart-define-from-file.md.
/// Pública para que `main_*.dart` arme `InfoEntorno` (host visible al pie
/// del login) del mismo valor que usa `ApiClient`, no de una copia.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
