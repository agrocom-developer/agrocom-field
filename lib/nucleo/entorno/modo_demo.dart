/// Perfil demo: con `--dart-define-from-file=config/env.demo.json` cada
/// flavor corre contra repositorios en memoria con datos ficticios, sin
/// servidor, sin red y sin base local. Sirve para ver y probar la interfaz
/// sin depender del backend (ADR 0010).
///
/// Nunca se activa por defecto: un build sin el flag es un build real.
const bool modoDemo = bool.fromEnvironment('MODO_DEMO');

/// Con `SESION_DEMO` el flavor cliente arranca con la sesión iniciada y la
/// presentación vista, para no repetir el ingreso en cada reinicio. Sin él, la
/// demo arranca como recién instalada (presentación, acceso e inicio).
const bool sesionDemo = bool.fromEnvironment('SESION_DEMO');
