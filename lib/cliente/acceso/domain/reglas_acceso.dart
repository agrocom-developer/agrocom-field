/// Validación local de los formularios de acceso. Devuelve el mensaje a
/// mostrar junto al campo, o `null` si el valor es aceptable. El servidor
/// vuelve a validar: estas reglas solo evitan un viaje de red inútil.
abstract final class ReglasAcceso {
  static const int largoMinimoContrasena = 8;

  static final _correo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? nombre(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe tu nombre';
    if (v.length < 3) return 'Escribe tu nombre completo';
    return null;
  }

  static String? telefono(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 'Escribe tu teléfono';
    if (digitos.length < 7) return 'El teléfono tiene muy pocos dígitos';
    return null;
  }

  static String? correo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe tu correo';
    if (!_correo.hasMatch(v)) return 'Revisa el correo: falta algo';
    return null;
  }

  /// Al iniciar sesión solo se exige que no esté vacía: la regla de largo
  /// aplica al crear la contraseña.
  static String? contrasena(String? valor) {
    if ((valor ?? '').isEmpty) return 'Escribe tu contraseña';
    return null;
  }

  static String? contrasenaNueva(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Crea una contraseña';
    if (v.length < largoMinimoContrasena) {
      return 'Usa al menos $largoMinimoContrasena caracteres';
    }
    return null;
  }
}
