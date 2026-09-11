import 'package:bloc/bloc.dart';

import '../../nucleo/auth/login_service.dart';
import '../../nucleo/auth/resultado_login.dart';
import '../../nucleo/flavor.dart';
import 'login_estado.dart';

/// Adaptador delgado entre `LoginService` (nucleo/auth, sin BLoC) y la
/// pantalla de login — mismo criterio que `SyncCubit` sobre `SyncEngine`.
///
/// Necesita el [Flavor] para decidir qué hacer ante un `409` (HU-69, ADR
/// 0005 de este repo): en `piloto` (RC, hardware dedicado) no cambia nada
/// — sigue mostrando el mensaje genérico de siempre, sin selector. En
/// `auxiliar` (celular) emite [LoginRequiereSeleccionRol] con los roles
/// del cuerpo, y retiene `usuario`/`contrasena` en memoria (nunca en
/// disco — el ADR descarta explícitamente persistirlas) para poder
/// reintentar el login con el `role_id` elegido vía [elegirRol].
class LoginCubit extends Cubit<LoginEstado> {
  LoginCubit(this._loginService, this._flavor) : super(const LoginInicial());

  final LoginService _loginService;
  final Flavor _flavor;

  String? _usuario;
  String? _contrasena;

  Future<void> ingresar({
    required String usuario,
    required String contrasena,
  }) async {
    _usuario = usuario;
    _contrasena = contrasena;
    emit(const LoginCargando());
    final resultado = await _loginService.login(
      usuario: usuario,
      contrasena: contrasena,
    );
    emit(_estadoDe(resultado));
  }

  /// Reintenta el login con las credenciales retenidas del intento en
  /// curso más el `role_id` elegido en el selector — nunca se llama sin
  /// haber pasado antes por [LoginRequiereSeleccionRol].
  Future<void> elegirRol(int rolId) async {
    final usuario = _usuario;
    final contrasena = _contrasena;
    if (usuario == null || contrasena == null) return;
    emit(const LoginCargando());
    final resultado = await _loginService.login(
      usuario: usuario,
      contrasena: contrasena,
      roleId: rolId,
    );
    emit(_estadoDe(resultado));
  }

  LoginEstado _estadoDe(ResultadoLogin resultado) => switch (resultado) {
    LoginExitoso() => const LoginExitosoEstado(),
    LoginCredencialesInvalidas() => const LoginFallido(
      'Usuario o contraseña incorrectos.',
    ),
    LoginRolAmbiguo(:final roles) =>
      _flavor == Flavor.auxiliar
          ? LoginRequiereSeleccionRol(roles)
          : const LoginFallido(
              'Tu usuario tiene más de un rol activo. Todavía no se puede '
              'elegir desde la app — pedile a Agrocom que lo resuelva.',
            ),
    LoginDatosInvalidos(:final mensaje) => LoginFallido(mensaje),
    LoginSinConexion() => const LoginFallido(
      'Sin conexión. Probá de nuevo cuando tengas señal.',
    ),
    LoginErrorDesconocido() => const LoginFallido(
      'Ocurrió un error inesperado. Probá de nuevo.',
    ),
  };
}
