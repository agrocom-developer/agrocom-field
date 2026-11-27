/// Sesión del cliente: lo mínimo que la interfaz necesita para saludar y
/// para saber que hay alguien dentro. El token nunca sale del repositorio.
class SesionCliente {
  const SesionCliente({
    required this.nombre,
    required this.usuario,
    this.empresa,
    this.telefono,
    this.enEliminacion = false,
  });

  final String nombre;
  final String usuario;
  final String? empresa;
  final String? telefono;

  /// La cuenta está en los 7 días de gracia de su eliminación: la sesión es
  /// restringida (solo ve el estado, conserva la cuenta o cierra sesión).
  final bool enEliminacion;

  /// Primer nombre, para el saludo.
  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  @override
  bool operator ==(Object other) =>
      other is SesionCliente &&
      other.nombre == nombre &&
      other.usuario == usuario &&
      other.empresa == empresa &&
      other.telefono == telefono &&
      other.enEliminacion == enEliminacion;

  @override
  int get hashCode =>
      Object.hash(nombre, usuario, empresa, telefono, enEliminacion);
}

/// Quién es el cliente ante Agrocom (`tipo` del contrato).
enum TipoCliente { persona, empresa }

/// Datos del formulario de registro del cliente. El registro es siempre de una
/// persona; con «Asociar a una empresa» envía además razón social y documento
/// fiscal (NIT) y esa persona queda como contacto principal de la empresa.
class DatosRegistroCliente {
  const DatosRegistroCliente({
    required this.nombre,
    required this.telefono,
    required this.usuario,
    required this.contrasena,
    this.tipo = TipoCliente.persona,
    this.razonSocial,
    this.documentoFiscal,
    this.cargo,
  });

  final TipoCliente tipo;
  final String? razonSocial;
  final String? documentoFiscal;

  /// Cargo de quien se registra en la empresa; opcional. Solo se envía con
  /// `tipo` empresa: la persona queda como contacto principal.
  final String? cargo;

  final String nombre;
  final String telefono;
  final String usuario;
  final String contrasena;
}

/// Campos del acceso; sirven de clave para los errores que el servidor
/// devuelve por campo (`422`).
enum CampoAcceso {
  nombre,
  telefono,
  usuario,
  contrasena,
  razonSocial,
  documentoFiscal,
}

enum MotivoFalloAcceso {
  /// Usuario o contraseña incorrectos.
  credencialesInvalidas,

  /// No hay red o el servidor no respondió. Lo escrito se conserva.
  sinConexion,

  /// El servidor rechazó uno o más campos; ver `porCampo`.
  validacion,

  /// Cualquier otra respuesta inesperada.
  desconocido,

  /// `409 cuenta_ya_registrada`: ese teléfono o documento ya tiene cuenta.
  cuentaYaRegistrada,

  /// `429`: demasiados intentos; ver `AccesoExcepcion.esperaSegundos`.
  demasiadosIntentos,
}

class AccesoExcepcion implements Exception {
  const AccesoExcepcion(
    this.motivo, {
    this.porCampo = const {},
    this.esperaSegundos,
    this.tipoCuenta,
  });

  final MotivoFalloAcceso motivo;
  final Map<CampoAcceso, String> porCampo;

  /// `Retry-After` de un `429`, en segundos.
  final int? esperaSegundos;

  /// `tipo_cuenta` de un `409 cuenta_ya_registrada` (`cliente`, `proveedor`).
  final String? tipoCuenta;

  @override
  String toString() => 'AccesoExcepcion(${motivo.name})';
}

/// Acceso del cliente: primer uso, inicio de sesión, registro y cierre.
/// Online-first (ADR 0009): iniciar sesión y registrarse requieren red. Las
/// pantallas solo conocen esta interfaz; la contraseña no se guarda en el
/// dispositivo.
abstract interface class AccesoRepositorio {
  /// Sesión guardada en el dispositivo, o `null` si no hay nadie dentro.
  Future<SesionCliente?> sesionActual();

  /// `true` cuando la persona ya recorrió la presentación inicial.
  Future<bool> onboardingVisto();

  Future<void> marcarOnboardingVisto();

  /// Lanza [AccesoExcepcion] si no se puede entrar.
  Future<SesionCliente> iniciarSesion({
    required String usuario,
    required String contrasena,
  });

  /// Crea la cuenta y deja la sesión iniciada. Lanza [AccesoExcepcion].
  Future<SesionCliente> registrar(DatosRegistroCliente datos);

  Future<void> cerrarSesion();
}
