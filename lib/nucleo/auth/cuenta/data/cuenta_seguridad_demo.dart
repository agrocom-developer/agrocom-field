import '../domain/cuenta_seguridad.dart';

/// En memoria, para el modo demo y las pruebas. Como el servidor en modo de
/// desarrollo, el código válido es siempre `000000`.
class CuentaSeguridadDemo implements CuentaSeguridadRepositorio {
  CuentaSeguridadDemo({
    this.telefonoVerificado = false,
    this.canalesCaidos = const {},
    this.impedimentos = const [],
    DateTime Function()? ahora,
  }) : _ahora = ahora ?? DateTime.now;

  static const codigoValido = '000000';

  bool telefonoVerificado;

  /// Canales que responden `503 canal_no_disponible`.
  final Set<CanalCodigo> canalesCaidos;
  final List<ImpedimentoEliminacion> impedimentos;
  final DateTime Function() _ahora;

  EliminacionCuenta? _eliminacion;
  String contrasena = 'demo';

  void _canal(CanalCodigo canal) {
    if (canalesCaidos.contains(canal)) throw CuentaCanalNoDisponible(canal);
  }

  void _codigo(String codigo) {
    if (codigo.trim() != codigoValido) throw const CuentaCodigoInvalido();
  }

  @override
  Future<void> pedirRecuperacion({
    required String identificador,
    required AppCuenta app,
    required CanalCodigo canal,
  }) async => _canal(canal);

  @override
  Future<String> confirmarRecuperacion({
    required String identificador,
    required AppCuenta app,
    required String codigo,
    required String contrasenaNueva,
  }) async {
    _codigo(codigo);
    contrasena = contrasenaNueva;
    return 'demo.usuario';
  }

  @override
  Future<CodigoEnviado> pedirCodigoContrasena(CanalCodigo canal) async {
    _canal(canal);
    return const CodigoEnviado(destino: '+591 ••••• 45');
  }

  @override
  Future<void> cambiarContrasena({
    required String codigo,
    required String contrasenaNueva,
  }) async {
    _codigo(codigo);
    contrasena = contrasenaNueva;
  }

  @override
  Future<CodigoEnviado> pedirCodigoTelefono(CanalCodigo canal) async {
    if (telefonoVerificado) throw const CuentaTelefonoYaVerificado();
    _canal(canal);
    return const CodigoEnviado(destino: '+591 ••••• 45');
  }

  @override
  Future<void> confirmarTelefono(String codigo) async {
    _codigo(codigo);
    telefonoVerificado = true;
  }

  @override
  Future<PerfilSeguridad> perfil() async =>
      PerfilSeguridad(telefonoVerificado: telefonoVerificado);

  @override
  Future<bool> renovarSiCorresponde({
    Duration margen = const Duration(days: 7),
  }) async => false;

  @override
  Future<ConsultaEliminacion> consultarEliminacion() async =>
      ConsultaEliminacion(
        eliminacion: _eliminacion,
        impedimentos: impedimentos,
      );

  @override
  Future<CodigoEnviado> pedirCodigoEliminacion(CanalCodigo canal) async {
    _canal(canal);
    return const CodigoEnviado(destino: '+591 ••••• 45');
  }

  @override
  Future<EliminacionCuenta> eliminarCuenta({
    String? contrasena,
    String? codigo,
  }) async {
    if (impedimentos.isNotEmpty) throw CuentaEliminacionBloqueada(impedimentos);
    if (codigo != null) {
      _codigo(codigo);
    } else if (contrasena != this.contrasena) {
      throw const CuentaContrasenaIncorrecta();
    }
    final ahora = _ahora();
    return _eliminacion = EliminacionCuenta(
      estado: EstadoEliminacion.solicitada,
      solicitadaEn: ahora,
      ejecutarDesde: ahora.add(const Duration(days: 7)),
    );
  }

  @override
  Future<EliminacionCuenta> conservarCuenta() async {
    final actual = _eliminacion;
    if (actual == null) throw const CuentaErrorDesconocido();
    _eliminacion = null;
    return EliminacionCuenta(
      estado: EstadoEliminacion.cancelada,
      solicitadaEn: actual.solicitadaEn,
      ejecutarDesde: actual.ejecutarDesde,
    );
  }
}
