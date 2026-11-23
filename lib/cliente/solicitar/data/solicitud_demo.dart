import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/solicitud_repositorio.dart';

/// Tarifa ficticia de la demo, en bolivianos por hectárea.
final _tarifaPorHectarea = Decimal.parse('90.00');

class SolicitudDemo implements SolicitudRepositorio {
  SolicitudDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 700),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  @override
  Future<List<Lote>> lotesDelCliente() async => _almacen.datos.lotes;

  @override
  Future<List<String>> productosSugeridos() async => const [
    'Glifosato 480 SL + coadyuvante',
    'Fungicida triazol + estrobilurina',
    'Insecticida piretroide',
    'Herbicida de preemergencia',
    'Fertilizante foliar',
  ];

  @override
  Future<EstimacionServicio> estimar({
    required Lote lote,
    required Decimal dosisLitrosPorHectarea,
  }) async => EstimacionServicio(
    precio: lote.hectareas * _tarifaPorHectarea,
    litros: lote.hectareas * dosisLitrosPorHectarea,
    precioPorHectarea: _tarifaPorHectarea,
  );

  @override
  Future<Servicio> solicitar(SolicitudServicio solicitud) async {
    await Future<void>.delayed(latencia);
    final nuevo = Servicio(
      id: 'srv-${1048 + _almacen.servicios.length - _almacen.datos.servicios.length}',
      lote: solicitud.lote,
      producto: solicitud.producto,
      dosisLitrosPorHectarea: solicitud.dosisLitrosPorHectarea,
      hectareasDeclaradas: solicitud.lote.hectareas,
      hectareasCubiertas: Decimal.zero,
      fechaDeseada: solicitud.fechaDeseada,
      estado: EstadoServicio.buscandoProveedor,
      precio: solicitud.lote.hectareas * _tarifaPorHectarea,
      solicitadoEn: _almacen.datos.ahora,
      clienteNombre: 'Hugo Antelo Suárez',
    );
    return _almacen.agregarSolicitud(solicitud, nuevo);
  }
}
