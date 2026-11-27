/// Seguridad de la cuenta que comparten los dos flavors: recuperar el acceso,
/// cambiar la contraseña, verificar el teléfono, renovar la sesión y eliminar
/// la cuenta. Todo es en línea y lo decide el servidor (ADR 0046 y 0047 de
/// `agrocom-api`); la app muestra, envía y explica.
library;

/// Por dónde llega el código de 6 dígitos.
enum CanalCodigo {
  whatsapp('whatsapp'),
  sms('sms'),
  correo('correo');

  const CanalCodigo(this.codigo);

  /// Valor del contrato (`canal`).
  final String codigo;

  static CanalCodigo? deCodigo(Object? codigo) {
    for (final c in values) {
      if (c.codigo == codigo) return c;
    }
    return null;
  }

  /// Canales que sirven para verificar el teléfono: el correo no prueba la
  /// posesión del teléfono.
  static const paraTelefono = [whatsapp, sms];
}

/// Desde qué app se escribe: el mismo teléfono puede estar en una cuenta de
/// cada tipo, así que el servidor lo necesita para recuperar la correcta.
enum AppCuenta {
  cliente('cliente'),
  proveedor('proveedor');

  const AppCuenta(this.codigo);
  final String codigo;
}

/// El servidor envió el código. [destino] ya viene enmascarado
/// (`+591 ••••• 45`); la app nunca conoce el número completo.
class CodigoEnviado {
  const CodigoEnviado({this.destino});

  final String? destino;
}

/// Lo que dice la sesión sobre la seguridad de la cuenta.
class PerfilSeguridad {
  const PerfilSeguridad({
    required this.telefonoVerificado,
    this.expiraEn,
    this.fotoUrl,
  });

  final bool telefonoVerificado;

  /// Cuándo caduca el token de este dispositivo; `null` si no caduca.
  final DateTime? expiraEn;
  final String? fotoUrl;
}

/// Qué impide hoy eliminar la cuenta (`409 eliminacion_bloqueada`).
enum ImpedimentoEliminacion {
  servicioEnCurso('servicio_en_curso'),
  reclamoAbierto('reclamo_abierto'),
  pilotosVinculados('pilotos_vinculados');

  const ImpedimentoEliminacion(this.codigo);
  final String codigo;

  static ImpedimentoEliminacion? deCodigo(Object? codigo) {
    for (final i in values) {
      if (i.codigo == codigo) return i;
    }
    return null;
  }
}

enum EstadoEliminacion {
  /// Dentro de la gracia: se puede conservar la cuenta.
  solicitada,

  /// Vencida la gracia, algo la impide todavía y se reintenta cada día.
  pospuesta,
  cancelada,
  ejecutada;

  static EstadoEliminacion deCodigo(Object? codigo) => switch (codigo) {
    'pospuesta' => pospuesta,
    'cancelada' => cancelada,
    'ejecutada' => ejecutada,
    _ => solicitada,
  };
}

/// Una solicitud de eliminación de la cuenta.
class EliminacionCuenta {
  const EliminacionCuenta({
    required this.estado,
    required this.solicitadaEn,
    required this.ejecutarDesde,
  });

  final EstadoEliminacion estado;
  final DateTime solicitadaEn;

  /// Hasta esta fecha la persona puede arrepentirse.
  final DateTime ejecutarDesde;

  /// La cuenta sigue en gracia o pospuesta: la sesión es restringida.
  bool get vigente =>
      estado == EstadoEliminacion.solicitada ||
      estado == EstadoEliminacion.pospuesta;

  /// Días enteros que faltan para `ejecutarDesde` (0 si ya pasó).
  int diasRestantes(DateTime ahora) {
    final falta = ejecutarDesde.difference(ahora);
    if (falta.isNegative) return 0;
    return (falta.inHours / 24).ceil();
  }
}

/// `GET /api/cuenta/eliminacion`: la solicitud vigente (si hay) y lo que
/// impediría pedirla hoy.
class ConsultaEliminacion {
  const ConsultaEliminacion({this.eliminacion, this.impedimentos = const []});

  final EliminacionCuenta? eliminacion;
  final List<ImpedimentoEliminacion> impedimentos;

  bool get enGracia => eliminacion?.vigente ?? false;
  bool get bloqueada => impedimentos.isNotEmpty;
}

/// Por qué falló una operación de cuenta. Cada caso tiene su texto y su
/// salida en `textos_cuenta_seguridad.dart`.
sealed class CuentaFalla implements Exception {
  const CuentaFalla();
}

/// Sin red o el servidor no respondió; lo escrito se conserva.
final class CuentaSinConexion extends CuentaFalla {
  const CuentaSinConexion();
}

/// `422 codigo_invalido`: errado, vencido, usado o con los intentos agotados
/// (el servidor no los distingue).
final class CuentaCodigoInvalido extends CuentaFalla {
  const CuentaCodigoInvalido();
}

/// `422 contrasena_incorrecta` al eliminar con la contraseña.
final class CuentaContrasenaIncorrecta extends CuentaFalla {
  const CuentaContrasenaIncorrecta();
}

/// `422 sin_destino`: la cuenta no tiene teléfono o correo para ese canal.
final class CuentaSinDestino extends CuentaFalla {
  const CuentaSinDestino(this.canal);
  final CanalCodigo? canal;
}

/// `503 canal_no_disponible`: ese medio no está configurado en el servidor.
/// No es culpa de la persona; se ofrece otro canal.
final class CuentaCanalNoDisponible extends CuentaFalla {
  const CuentaCanalNoDisponible(this.canal);
  final CanalCodigo? canal;
}

/// `429`: demasiados intentos; reintentar tras [espera] (`Retry-After`).
final class CuentaLimiteExcedido extends CuentaFalla {
  const CuentaLimiteExcedido({this.espera});
  final Duration? espera;
}

/// `409 telefono_ya_verificado`.
final class CuentaTelefonoYaVerificado extends CuentaFalla {
  const CuentaTelefonoYaVerificado();
}

/// `409 eliminacion_bloqueada`.
final class CuentaEliminacionBloqueada extends CuentaFalla {
  const CuentaEliminacionBloqueada(this.motivos);
  final List<ImpedimentoEliminacion> motivos;
}

/// `422` con errores por campo (`password_nueva` corta, por ejemplo).
final class CuentaDatosInvalidos extends CuentaFalla {
  const CuentaDatosInvalidos({this.mensaje, this.porCampo = const {}});
  final String? mensaje;
  final Map<String, String> porCampo;
}

/// `401`: el token venció o lo revocaron.
final class CuentaSesionVencida extends CuentaFalla {
  const CuentaSesionVencida();
}

/// `403 cuenta_en_eliminacion`: la sesión solo puede ver el estado, cancelar
/// y cerrar sesión.
final class CuentaEnEliminacion extends CuentaFalla {
  const CuentaEnEliminacion();
}

final class CuentaErrorDesconocido extends CuentaFalla {
  const CuentaErrorDesconocido();
}

/// Contraseña: mínimo 4 caracteres, máximo 100, sin reglas de composición
/// (la misma validación que hace el servidor).
abstract final class ReglasContrasena {
  static const int largoMinimo = 4;
  static const int largoMaximo = 100;

  /// Mensaje junto al campo, o `null` si la contraseña es aceptable.
  static String? validarNueva(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Crea una contraseña';
    if (v.length < largoMinimo) {
      return 'Usa al menos $largoMinimo caracteres';
    }
    if (v.length > largoMaximo) {
      return 'Usa $largoMaximo caracteres como máximo';
    }
    return null;
  }

  /// Al iniciar sesión solo se exige que no esté vacía.
  static String? validarIngreso(String? valor) {
    if ((valor ?? '').isEmpty) return 'Escribe tu contraseña';
    return null;
  }
}

/// Operaciones de seguridad de la cuenta. Las pantallas solo conocen esta
/// interfaz. Todas lanzan una [CuentaFalla].
abstract interface class CuentaSeguridadRepositorio {
  /// `POST /api/auth/recuperar`: el servidor responde siempre igual, exista o
  /// no la cuenta. [identificador] es usuario, teléfono o correo.
  Future<void> pedirRecuperacion({
    required String identificador,
    required AppCuenta app,
    required CanalCodigo canal,
  });

  /// `POST /api/auth/recuperar/confirmar`. Devuelve el usuario de la cuenta
  /// para mostrárselo a quien lo olvidó.
  Future<String> confirmarRecuperacion({
    required String identificador,
    required AppCuenta app,
    required String codigo,
    required String contrasenaNueva,
  });

  /// `POST /api/cuenta/contrasena/codigo` (con sesión).
  Future<CodigoEnviado> pedirCodigoContrasena(CanalCodigo canal);

  /// `PUT /api/cuenta/contrasena`: cierra la sesión de los demás
  /// dispositivos y conserva la actual.
  Future<void> cambiarContrasena({
    required String codigo,
    required String contrasenaNueva,
  });

  /// `POST /api/cuenta/telefono/verificacion` (solo WhatsApp o SMS).
  Future<CodigoEnviado> pedirCodigoTelefono(CanalCodigo canal);

  /// `POST /api/cuenta/telefono/verificacion/confirmar`.
  Future<void> confirmarTelefono(String codigo);

  /// `GET /api/auth/sesion`: si el teléfono ya está verificado y cuándo
  /// caduca el token.
  Future<PerfilSeguridad> perfil();

  /// `POST /api/auth/renovar` cuando al token le quedan menos de [margen].
  /// Devuelve `true` si lo renovó. Nunca lanza: una falla de red se ignora y
  /// la sesión sigue con el token guardado.
  Future<bool> renovarSiCorresponde({
    Duration margen = const Duration(days: 7),
  });

  /// `GET /api/cuenta/eliminacion`.
  Future<ConsultaEliminacion> consultarEliminacion();

  /// `POST /api/cuenta/eliminacion/codigo`.
  Future<CodigoEnviado> pedirCodigoEliminacion(CanalCodigo canal);

  /// `POST /api/cuenta/eliminacion` con la contraseña **o** el código. Si
  /// prospera, el servidor revoca todos los tokens: quien llama cierra la
  /// sesión local.
  Future<EliminacionCuenta> eliminarCuenta({
    String? contrasena,
    String? codigo,
  });

  /// `POST /api/cuenta/eliminacion/cancelar`: «Conservar mi cuenta».
  Future<EliminacionCuenta> conservarCuenta();
}

/// Renueva la sesión al desbloquear con biometría. Lo implementa
/// [CuentaSeguridadRepositorio].
typedef RenovadorSesion = Future<bool> Function();
