import 'package:bloc/bloc.dart';

import '../../nucleo/auth/login_service.dart';
import '../../nucleo/auth/resultado_login.dart';
import 'login_estado.dart';

/// Adaptador delgado entre `LoginService` (nucleo/auth, sin BLoC) y la
/// pantalla de login — mismo criterio que `SyncCubit` sobre `SyncEngine`.
class LoginCubit extends Cubit<LoginEstado> {
  LoginCubit(this._loginService) : super(const LoginInicial());

  final LoginService _loginService;

  Future<void> ingresar({
    required String usuario,
    required String contrasena,
  }) async {
    emit(const LoginCargando());
    final resultado = await _loginService.login(
      usuario: usuario,
      contrasena: contrasena,
    );
    emit(_estadoDe(resultado));
  }

  LoginEstado _estadoDe(ResultadoLogin resultado) => switch (resultado) {
    LoginExitoso() => const LoginExitosoEstado(),
    LoginCredencialesInvalidas() => const LoginFallido(
      'Usuario o contraseña incorrectos.',
    ),
    LoginRolAmbiguo() => const LoginFallido(
      'Tu usuario tiene más de un rol activo. Todavía no se puede elegir '
      'desde la app — pedile a Agrocom que lo resuelva.',
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
