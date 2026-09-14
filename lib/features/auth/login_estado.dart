import '../../nucleo/auth/rol_activo.dart';

/// Estado de `LoginCubit` — pantalla simple, alcanza con inicial/cargando/
/// exitoso/error (ver HU-03: "estados inicial/cargando/error, así que
/// Cubit alcanza") más el selector de rol del flavor `auxiliar` (HU-69,
/// ADR 0005).
sealed class LoginEstado {
  const LoginEstado();
}

final class LoginInicial extends LoginEstado {
  const LoginInicial();
}

final class LoginCargando extends LoginEstado {
  const LoginCargando();
}

/// El widget que escucha este estado navega al placeholder — no hay nada
/// más que mostrar acá.
final class LoginExitosoEstado extends LoginEstado {
  const LoginExitosoEstado();
}

final class LoginFallido extends LoginEstado {
  const LoginFallido(this.mensaje);

  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is LoginFallido && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}

/// `409` en el flavor `auxiliar` (HU-69, ADR 0005 de este repo): el
/// usuario tiene más de un rol vivo. La pantalla muestra un selector con
/// [roles] y llama a `LoginCubit.elegirRol` con el `id` elegido. En el
/// flavor `piloto` este estado nunca se emite — ahí un `409` sigue siendo
/// `LoginFallido` con el mensaje genérico de siempre.
final class LoginRequiereSeleccionRol extends LoginEstado {
  const LoginRequiereSeleccionRol(this.roles);

  final List<RolActivo> roles;

  @override
  bool operator ==(Object other) {
    if (other is! LoginRequiereSeleccionRol ||
        other.roles.length != roles.length) {
      return false;
    }
    for (var i = 0; i < roles.length; i++) {
      if (other.roles[i] != roles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(roles);
}
