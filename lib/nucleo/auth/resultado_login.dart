import 'rol_activo.dart';

/// Resultado distinguible de un intento de `LoginService.login` — un
/// resultado por cada respuesta del contrato (`POST /api/auth/token`,
/// operationId `emitirTokenDispositivo`) más el caso sin red.
sealed class ResultadoLogin {
  const ResultadoLogin();
}

/// `201` — token emitido y ya guardado en `TokenStore`.
final class LoginExitoso extends ResultadoLogin {
  const LoginExitoso();
}

/// `401` — usuario o contraseña incorrectos.
final class LoginCredencialesInvalidas extends ResultadoLogin {
  const LoginCredencialesInvalidas();
}

/// `409` — el usuario tiene más de un rol vivo, sin guardar ningún token a
/// medias. [roles] trae los roles vivos del cuerpo del error (ADR 0005 de
/// este repo): en el flavor `auxiliar`, `LoginCubit` los usa para mostrar
/// un selector y reintentar el login con el `role_id` elegido; en
/// `piloto`, sigue mostrando un mensaje genérico sin selector.
final class LoginRolAmbiguo extends ResultadoLogin {
  const LoginRolAmbiguo(this.roles);

  final List<RolActivo> roles;

  @override
  bool operator ==(Object other) {
    if (other is! LoginRolAmbiguo || other.roles.length != roles.length) {
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

/// `422` — falta algún campo obligatorio o el payload es inválido.
final class LoginDatosInvalidos extends ResultadoLogin {
  const LoginDatosInvalidos(this.mensaje);

  final String mensaje;

  @override
  bool operator ==(Object other) =>
      other is LoginDatosInvalidos && other.mensaje == mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}

/// Sin conectividad o timeout — el caso normal en el lote, no un error de
/// servidor (`ApiExcepcionRed`).
final class LoginSinConexion extends ResultadoLogin {
  const LoginSinConexion();
}

/// Cualquier otra falla (código de servidor inesperado, respuesta
/// desconocida) que no encaja en los casos de arriba.
final class LoginErrorDesconocido extends ResultadoLogin {
  const LoginErrorDesconocido();
}
