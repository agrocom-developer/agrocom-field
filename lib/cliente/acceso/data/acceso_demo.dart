import '../../../nucleo/marketplace/demo/datos_demo.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/acceso_repositorio.dart';

/// Acceso en memoria del modo demo (ADR 0010). No hay cuentas reales:
/// cualquier usuario entra con una contraseña de 8 caracteres o
/// más. Tres valores fijos permiten ver los estados de error:
///
/// - usuario [usuarioSinConexion]: responde como si no hubiera red;
/// - contraseña [contrasenaIncorrecta]: credenciales inválidas;
/// - registro con [usuarioOcupado]: error de validación junto al campo.
class AccesoDemo implements AccesoRepositorio {
  AccesoDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 700),
    bool onboardingVisto = false,
    bool sesionIniciada = false,
  }) : _onboardingVisto = onboardingVisto {
    if (sesionIniciada) _almacen.sesion = sesionBase;
  }

  static const usuarioSinConexion = 'sinred';
  static const usuarioOcupado = 'ocupado';
  static const contrasenaIncorrecta = 'incorrecta';

  /// El cliente ficticio de los datos demo.
  static const sesionBase = SesionCliente(
    nombre: DatosDemo.clienteNombre,
    empresa: DatosDemo.clienteEmpresa,
    usuario: 'hugo.antelo',
    telefono: '+591 7712 3456',
  );

  final AlmacenDemoCliente _almacen;
  final Duration latencia;
  bool _onboardingVisto;

  @override
  Future<SesionCliente?> sesionActual() async => _almacen.sesion;

  @override
  Future<bool> onboardingVisto() async => _onboardingVisto;

  @override
  Future<void> marcarOnboardingVisto() async => _onboardingVisto = true;

  @override
  Future<SesionCliente> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    await Future<void>.delayed(latencia);
    final c = usuario.trim().toLowerCase();
    if (c == usuarioSinConexion) {
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    }
    if (contrasena == contrasenaIncorrecta || contrasena.length < 8) {
      throw const AccesoExcepcion(MotivoFalloAcceso.credencialesInvalidas);
    }
    final sesion = SesionCliente(
      nombre: sesionBase.nombre,
      empresa: sesionBase.empresa,
      usuario: c,
      telefono: sesionBase.telefono,
    );
    _almacen.sesion = sesion;
    return sesion;
  }

  @override
  Future<SesionCliente> registrar(DatosRegistroCliente datos) async {
    await Future<void>.delayed(latencia);
    final c = datos.usuario.trim().toLowerCase();
    if (c == usuarioSinConexion) {
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    }
    if (c == usuarioOcupado) {
      throw const AccesoExcepcion(
        MotivoFalloAcceso.validacion,
        porCampo: {CampoAcceso.usuario: 'Ese usuario ya existe. Elige otro'},
      );
    }
    final sesion = SesionCliente(
      nombre: datos.nombre.trim(),
      usuario: c,
      telefono: datos.telefono.trim(),
    );
    _almacen.sesion = sesion;
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async => _almacen.sesion = null;
}
