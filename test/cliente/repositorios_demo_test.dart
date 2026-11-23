import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/calificar/data/calificacion_demo.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/servicios/data/servicios_cliente_demo.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

void main() {
  late AlmacenDemoCliente almacen;
  setUp(() => almacen = AlmacenDemoCliente());

  test('solicitar con la misma clave no crea dos servicios', () async {
    final repo = SolicitudDemo(almacen, latencia: Duration.zero);
    final lote = (await repo.lotesDelCliente()).first;
    final solicitud = SolicitudServicio(
      lote: lote,
      producto: 'Glifosato',
      dosisLitrosPorHectarea: Decimal.parse('2.4'),
      fechaDeseada: DateTime(2026, 12, 1),
      claveIdempotencia: 'clave-1',
    );
    final antes = almacen.servicios.length;
    final a = await repo.solicitar(solicitud);
    final b = await repo.solicitar(solicitud);
    expect(b.id, a.id);
    expect(almacen.servicios.length, antes + 1);
    expect(a.estado, EstadoServicio.buscandoProveedor);
    final lista = await ServiciosClienteDemo(almacen).observar().first;
    expect(lista.first.id, a.id);
  });

  test('la estimación usa decimales exactos', () async {
    final repo = SolicitudDemo(almacen, latencia: Duration.zero);
    final lote = almacen.datos.lotes[1]; // 85.5 ha
    final e = await repo.estimar(
      lote: lote,
      dosisLitrosPorHectarea: Decimal.parse('0.8'),
    );
    expect(e.precio, Decimal.parse('7695.00'));
    expect(e.litros, Decimal.parse('68.40'));
  });

  test('calificar guarda el puntaje una sola vez', () async {
    final repo = CalificacionDemo(almacen);
    await repo.calificarProveedor(servicioId: 'srv-1036', puntaje: 4);
    await repo.calificarProveedor(servicioId: 'srv-1036', puntaje: 1);
    expect(almacen.porId('srv-1036')!.puntajeDelCliente, 4);
    final r = await repo.recibidas();
    expect(r.total, greaterThan(0));
  });

  test('el seguimiento avanza hasta completar el lote', () async {
    final repo = SeguimientoDemo(
      almacen,
      intervalo: Duration.zero,
      pasoHectareas: '40',
    );
    final cuadros = await repo.observar('srv-1042').toList();
    expect(cuadros.length, greaterThan(2));
    expect(cuadros.last.estado, EstadoServicio.completado);
    expect(
      cuadros.map((c) => c.hectareasCubiertas),
      orderedEquals([...cuadros.map((c) => c.hectareasCubiertas)]..sort()),
    );
  });
}
