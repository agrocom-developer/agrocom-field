import '../../../nucleo/auth/cuenta/domain/cuenta_seguridad.dart';

/// Validación local de los formularios de acceso. Devuelve el mensaje a
/// mostrar junto al campo, o `null` si el valor es aceptable. El servidor
/// vuelve a validar: estas reglas solo evitan un viaje de red inútil.
abstract final class ReglasAcceso {
  /// Mínimo de la contraseña: el mismo del servidor, sin reglas de
  /// composición (letras, números ni símbolos).
  static const int largoMinimoContrasena = ReglasContrasena.largoMinimo;

  /// Usuario de acceso: letras, números, punto, guion y guion bajo; nunca un
  /// correo.
  static final _usuario = RegExp(r'^[A-Za-z0-9._-]{3,40}$');

  static String? nombre(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe tu nombre';
    if (v.length < 3) return 'Escribe tu nombre completo';
    return null;
  }

  static String? razonSocial(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe la razón social de la empresa';
    return null;
  }

  static String? documentoFiscal(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe el NIT de la empresa';
    return null;
  }

  static String? telefono(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 'Escribe tu teléfono';
    if (digitos.length < 7) return 'El teléfono tiene muy pocos dígitos';
    return null;
  }

  static String? usuario(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe tu usuario';
    if (v.contains('@')) return 'Tu usuario no es un correo. Ejemplo: ana.roca';
    if (!_usuario.hasMatch(v)) {
      return 'Usa de 3 a 40 letras, números, punto o guion';
    }
    return null;
  }

  /// Al iniciar sesión solo se exige que no esté vacía: la regla de largo
  /// aplica al crear la contraseña.
  static String? contrasena(String? valor) {
    if ((valor ?? '').isEmpty) return 'Escribe tu contraseña';
    return null;
  }

  static String? contrasenaNueva(String? valor) =>
      ReglasContrasena.validarNueva(valor);

  /// Al iniciar sesión se puede escribir el usuario o el teléfono de la
  /// cuenta; el servidor decide cuál es.
  static String? usuarioOTelefono(String? valor) {
    if ((valor ?? '').trim().isEmpty) return 'Escribe tu usuario o teléfono';
    return null;
  }
}
