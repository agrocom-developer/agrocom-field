/// Por dónde recibe la persona el código de un solo uso. Son los tres canales
/// del contrato (`POST /api/cuenta/contrasena/codigo`); el nombre de cada
/// valor es el que viaja al servidor.
enum CanalCodigo { whatsapp, sms, correo }

/// El código ya salió: [destino] es adónde, enmascarado por el servidor
/// (`+591 ••••• 45`); se muestra tal cual, nunca se reconstruye.
class CodigoEnviado {
  const CodigoEnviado(this.destino);

  final String destino;
}

/// Cambio de contraseña con código (ADR 0046 de `agrocom-api`). Dos pasos:
/// pedir el código por un canal y enviarlo con la contraseña nueva. El
/// servidor no pide la contraseña actual: confirmar el código prueba la
/// posesión del canal.
///
/// Las dos operaciones requieren red; fallan con `SinConexion` u
/// `OperacionRechazada` (ver `FallaMarketplace`), cuyo `motivo` puede ser
/// `codigo_invalido`, `sin_destino`, `canal_no_disponible`,
/// `demasiados_codigos` o `reenvio_demasiado_pronto`.
abstract interface class ContrasenaRepositorio {
  Future<CodigoEnviado> pedirCodigo(CanalCodigo canal);

  /// Cambia la contraseña. Revoca los demás dispositivos y conserva este.
  Future<void> cambiar({required String codigo, required String passwordNueva});
}

/// Reglas que la app valida antes de enviar; el servidor decide en último
/// término. Devuelven `null` si el valor es válido, o el motivo en español.
abstract final class ReglasContrasena {
  /// El servidor exige al menos 4 caracteres y ninguna otra regla.
  static const minimo = 4;

  static const largoCodigo = 6;

  static String? codigo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe el código que te enviamos.';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
      return 'El código tiene $largoCodigo números.';
    }
    return null;
  }

  static String? nueva(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Escribe tu contraseña nueva.';
    if (v.length < minimo) {
      return 'Usa al menos $minimo caracteres.';
    }
    return null;
  }

  static String? confirmacion(String? valor, String nueva) {
    if ((valor ?? '').isEmpty) return 'Repite tu contraseña nueva.';
    if (valor != nueva) return 'Las contraseñas no coinciden.';
    return null;
  }
}
