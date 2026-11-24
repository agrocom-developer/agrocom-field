import 'dart:async';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/solicitud_repositorio.dart';

class SolicitudDemo implements SolicitudRepositorio {
  SolicitudDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 700),
    this.sinConexion = false,
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  /// Simula un dispositivo sin red: [publicar] falla hasta que vuelve a
  /// `false`.
  bool sinConexion;

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
  Future<List<String>> cultivosSugeridos() async => const [
    'Soya',
    'Maíz',
    'Girasol',
    'Trigo',
    'Sorgo',
    'Arroz',
    'Caña de azúcar',
  ];

  @override
  Future<Solicitud> publicar(NuevaSolicitud s) async {
    await Future<void>.delayed(latencia);
    if (sinConexion || _almacen.sinRed) throw const SolicitudSinConexion();
    final ahora = _almacen.ahora;
    final nueva = Solicitud(
      id: _almacen.nuevoId(),
      lote: s.lote,
      hectareas: s.hectareas,
      cultivo: s.cultivo,
      producto: s.producto,
      ventanaDesde: s.fechaDeseada,
      ventanaHasta: s.fechaDeseada.add(const Duration(days: 3)),
      observaciones: s.observaciones,
      accesos: s.accesos,
      precioHaPropuesto: s.precioHa,
      montoEstimado: s.total,
      estado: EstadoSolicitud.abierta,
      publicadaEn: ahora,
      venceEn: ahora.add(const Duration(days: 7)),
      historial: [
        CambioEstado(estado: EstadoSolicitud.abierta, momento: ahora),
      ],
      ofertasVigentes: 0,
    );
    return _almacen.agregarSolicitud(s.claveIdempotencia, nueva);
  }
}
