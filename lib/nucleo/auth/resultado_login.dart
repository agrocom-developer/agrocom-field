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

/// `409` — el usuario tiene más de un rol vivo. El selector de rol es
/// HU-69 (ADR 0005 de este repo), fuera de alcance acá: este resultado
/// solo existe para que la pantalla avise que ese caso no está soportado
/// todavía, sin guardar ningún token a medias.
final class LoginRolAmbiguo extends ResultadoLogin {
  const LoginRolAmbiguo();
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
