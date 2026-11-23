import '../../../nucleo/marketplace/demo/datos_demo.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/inicio_cliente_repositorio.dart';
import '../domain/reglas_inicio_cliente.dart';

/// Inicio del cliente en modo demo: arma el resumen con los servicios del
/// almacén en memoria y dos avisos fijos. Cada suscripción demora [latencia]
/// antes del primer dato para que el esqueleto de carga se pueda ver.
class InicioClienteDemo implements InicioClienteRepositorio {
  InicioClienteDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 600),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  static const avisos = [
    AvisoInicio(
      id: 'clima-favorable',
      titulo: 'Buen clima para aplicar mañana',
      detalle:
          'Viento de 8 km/h y sin lluvia hasta el mediodía en Cuatro '
          'Cañadas.',
    ),
    AvisoInicio(
      id: 'alta-demanda',
      titulo: 'Alta demanda esta semana',
      detalle:
          'Solicita con dos días de anticipación para asegurar la fecha '
          'que necesitas.',
      tono: TonoAvisoInicio.alerta,
    ),
  ];

  @override
  Stream<ResumenInicio> observar() async* {
    if (latencia > Duration.zero) await Future<void>.delayed(latencia);
    await for (final servicios in _almacen.observar()) {
      final sesion = _almacen.sesion;
      yield ReglasInicioCliente.resumir(
        nombre:
            sesion?.primerNombre ?? DatosDemo.clienteNombre.split(' ').first,
        empresa: sesion == null ? DatosDemo.clienteEmpresa : sesion.empresa,
        servicios: servicios,
        avisos: avisos,
      );
    }
  }
}
