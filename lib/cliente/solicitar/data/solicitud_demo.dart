import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/reglas_solicitud.dart';
import '../domain/solicitud_repositorio.dart';

/// Tarifa ficticia de la demo, en bolivianos por hectárea.
final _tarifaPorHectarea = Decimal.parse('90.00');

/// Recargo ficticio por urgencia: 10 % del subtotal.
final _recargoUrgencia = Decimal.parse('0.10');

/// Radio inicial en el que la demo ofrece el servicio a terceros.
const _radioTercerosKm = 50;

class SolicitudDemo implements SolicitudRepositorio {
  SolicitudDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 700),
    this.pasoBusqueda = const Duration(seconds: 4),
    this.sinConexion = false,
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  /// Cuánto dura cada ronda de la búsqueda de proveedor.
  final Duration pasoBusqueda;

  /// Simula un dispositivo sin red: [solicitar] falla hasta que vuelve a
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
  Future<EstimacionServicio> estimar({
    required Lote lote,
    required Decimal dosisLitrosPorHectarea,
    Decimal? hectareas,
    DateTime? fechaDeseada,
  }) async {
    final superficie = hectareas ?? lote.hectareas;
    final subtotal = superficie * _tarifaPorHectarea;
    final urgente =
        fechaDeseada != null &&
        ReglasSolicitud.esUrgente(fechaDeseada, _almacen.datos.ahora);
    final recargos = [
      if (urgente)
        RecargoServicio(
          concepto: 'Recargo por urgencia',
          monto: (subtotal * _recargoUrgencia).round(scale: 2),
        ),
    ];
    return EstimacionServicio(
      precio: recargos.fold(subtotal, (total, r) => total + r.monto),
      litros: superficie * dosisLitrosPorHectarea,
      precioPorHectarea: _tarifaPorHectarea,
      subtotal: subtotal,
      recargos: recargos,
    );
  }

  @override
  Future<Servicio> solicitar(SolicitudServicio solicitud) async {
    await Future<void>.delayed(latencia);
    if (sinConexion) throw const SolicitudSinConexion();
    final estimacion = await estimar(
      lote: solicitud.lote,
      dosisLitrosPorHectarea: solicitud.dosisLitrosPorHectarea,
      hectareas: solicitud.hectareas,
      fechaDeseada: solicitud.fechaDeseada,
    );
    final nuevo = Servicio(
      id: 'srv-${1048 + _almacen.servicios.length - _almacen.datos.servicios.length}',
      lote: solicitud.lote,
      producto: solicitud.producto,
      dosisLitrosPorHectarea: solicitud.dosisLitrosPorHectarea,
      hectareasDeclaradas: solicitud.hectareas,
      hectareasCubiertas: Decimal.zero,
      fechaDeseada: solicitud.fechaDeseada,
      estado: EstadoServicio.buscandoProveedor,
      precio: estimacion.precio,
      solicitadoEn: _almacen.datos.ahora,
      clienteNombre: 'Hugo Antelo Suárez',
    );
    return _almacen.agregarSolicitud(solicitud, nuevo);
  }

  /// La demo recorre las dos rondas (propios, luego terceros) y termina con
  /// un proveedor independiente que acepta, para que se vean las tres
  /// etapas. Al aceptar, el servicio pasa a `asignado` en el almacén.
  @override
  Stream<BusquedaProveedor> observarBusqueda(String servicioId) {
    Timer? temporizador;
    late final StreamController<BusquedaProveedor> salida;

    void asignar() {
      final servicio = _almacen.porId(servicioId);
      final proveedor = _almacen.datos.proveedores.firstWhere(
        (p) => p.tipo != TipoProveedor.propioAgrocom,
      );
      if (servicio != null &&
          servicio.estado == EstadoServicio.buscandoProveedor) {
        _almacen.reemplazar(
          servicio.copiarCon(
            estado: EstadoServicio.asignado,
            proveedor: proveedor,
          ),
        );
      }
      salida
        ..add(
          BusquedaProveedor(fase: FaseBusqueda.asignado, proveedor: proveedor),
        )
        ..close();
    }

    void ofrecerATerceros() {
      salida.add(
        const BusquedaProveedor(
          fase: FaseBusqueda.terceros,
          radioKm: _radioTercerosKm,
        ),
      );
      temporizador = Timer(pasoBusqueda, asignar);
    }

    salida = StreamController<BusquedaProveedor>(
      onListen: () {
        final servicio = _almacen.porId(servicioId);
        if (servicio?.proveedor != null) {
          salida
            ..add(
              BusquedaProveedor(
                fase: FaseBusqueda.asignado,
                proveedor: servicio!.proveedor,
              ),
            )
            ..close();
          return;
        }
        salida.add(const BusquedaProveedor(fase: FaseBusqueda.propios));
        temporizador = Timer(pasoBusqueda, ofrecerATerceros);
      },
      onCancel: () => temporizador?.cancel(),
    );
    return salida.stream;
  }
}
