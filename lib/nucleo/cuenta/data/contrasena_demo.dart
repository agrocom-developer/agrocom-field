import '../../marketplace/dominio/falla.dart';
import '../domain/contrasena_repositorio.dart';

/// En memoria, para el modo demo y las pruebas (ADR 0010). Cualquier código
/// de 6 dígitos sirve salvo [codigoIncorrecto]; el canal [CanalCodigo.sms]
/// responde sin destino para ver ese error.
class ContrasenaDemo implements ContrasenaRepositorio {
  ContrasenaDemo({this.latencia = const Duration(milliseconds: 600)});

  final Duration latencia;

  static const codigoIncorrecto = '000000';

  /// Última contraseña «guardada»; solo la ven las pruebas.
  String? ultimaContrasena;

  @override
  Future<CodigoEnviado> pedirCodigo(CanalCodigo canal) async {
    await Future<void>.delayed(latencia);
    if (canal == CanalCodigo.sms) {
      throw const OperacionRechazada(
        'Tu cuenta no tiene un teléfono para recibir mensajes. Elige otro medio.',
        codigo: 422,
        motivo: 'sin_destino',
      );
    }
    return CodigoEnviado(switch (canal) {
      CanalCodigo.whatsapp => '+591 ••••• 56',
      CanalCodigo.correo => 'h••••@agrocom.demo',
      CanalCodigo.sms => '',
    });
  }

  @override
  Future<void> cambiar({
    required String codigo,
    required String passwordNueva,
  }) async {
    await Future<void>.delayed(latencia);
    if (codigo == codigoIncorrecto || !RegExp(r'^\d{6}$').hasMatch(codigo)) {
      throw const OperacionRechazada(
        'El código no es válido o venció. Pide uno nuevo.',
        codigo: 422,
        motivo: 'codigo_invalido',
      );
    }
    ultimaContrasena = passwordNueva;
  }
}
