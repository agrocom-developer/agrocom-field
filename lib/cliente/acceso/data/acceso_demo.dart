import '../../../nucleo/marketplace/demo/datos_demo.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/acceso_repositorio.dart';

/// Acceso en memoria del modo demo (ADR 0010 y 0011). No hay cuentas reales:
/// cualquier correo bien escrito entra con una contraseña de 8 caracteres o
/// más. Tres valores fijos permiten ver los estados de error:
///
/// - correo [correoSinConexion]: responde como si no hubiera red;
/// - contraseña [contrasenaIncorrecta]: credenciales inválidas;
/// - registro con [correoOcupado]: error de validación junto al campo.
class AccesoDemo implements AccesoRepositorio {
  AccesoDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 700),
    bool onboardingVisto = false,
    bool sesionIniciada = false,
  }) : _onboardingVisto = onboardingVisto {
    if (sesionIniciada) _almacen.sesion = sesionBase;
  }

  static const correoSinConexion = 'sinred@agrocom.example';
  static const correoOcupado = 'ocupado@agrocom.example';
  static const contrasenaIncorrecta = 'incorrecta';

  /// El cliente ficticio de los datos demo.
  static const sesionBase = SesionCliente(
    nombre: DatosDemo.clienteNombre,
    empresa: DatosDemo.clienteEmpresa,
    correo: 'hugo.antelo@lostajibos.example',
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
    required String correo,
    required String contrasena,
  }) async {
    await Future<void>.delayed(latencia);
    final c = correo.trim().toLowerCase();
    if (c == correoSinConexion) {
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    }
    if (contrasena == contrasenaIncorrecta || contrasena.length < 8) {
      throw const AccesoExcepcion(MotivoFalloAcceso.credencialesInvalidas);
    }
    final sesion = SesionCliente(
      nombre: sesionBase.nombre,
      empresa: sesionBase.empresa,
      correo: c,
      telefono: sesionBase.telefono,
    );
    _almacen.sesion = sesion;
    return sesion;
  }

  @override
  Future<SesionCliente> registrar(DatosRegistroCliente datos) async {
    await Future<void>.delayed(latencia);
    final c = datos.correo.trim().toLowerCase();
    if (c == correoSinConexion) {
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    }
    if (c == correoOcupado) {
      throw const AccesoExcepcion(
        MotivoFalloAcceso.validacion,
        porCampo: {CampoAcceso.correo: 'Ya existe una cuenta con este correo'},
      );
    }
    final sesion = SesionCliente(
      nombre: datos.nombre.trim(),
      correo: c,
      telefono: datos.telefono.trim(),
    );
    _almacen.sesion = sesion;
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async => _almacen.sesion = null;
}
