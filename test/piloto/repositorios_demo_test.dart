import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/piloto/demo/almacen_demo_piloto.dart';
import 'package:agrocom_field/piloto/dron/data/drones_demo.dart';
import 'package:agrocom_field/piloto/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/piloto/perfil/data/perfil_demo.dart';
import 'package:agrocom_field/piloto/servicio_asignado/data/servicio_asignado_demo.dart';

void main() {
  late AlmacenDemoPiloto almacen;
  late OfertasDemo ofertas;
  setUp(() {
    almacen = AlmacenDemoPiloto();
    ofertas = OfertasDemo(almacen, latencia: Duration.zero);
  });

  test('aceptar una oferta la pasa a servicios asignados', () async {
    final r = await ofertas.aceptar('of-1', claveIdempotencia: 'k1');
    expect(r, ResultadoRespuestaOferta.aceptada);
    final asignados = await ServicioAsignadoDemo(almacen).observar().first;
    expect(asignados.length, 2);
    expect(
      (await ofertas.observar().first).any((o) => o.id == 'of-1'),
      isFalse,
    );
  });

  test('reintentar con la misma clave devuelve el mismo resultado', () async {
    final a = await ofertas.aceptar('of-1', claveIdempotencia: 'k1');
    final b = await ofertas.aceptar('of-1', claveIdempotencia: 'k1');
    expect(b, a);
    expect(almacen.asignados.length, 2);
  });

  test('una oferta puede perderse frente a otro proveedor', () async {
    final r = await ofertas.aceptar(
      ofertaPerdidaEnDemo,
      claveIdempotencia: 'k2',
    );
    expect(r, ResultadoRespuestaOferta.perdida);
    expect(almacen.asignados.length, 1);
  });

  test('rechazar quita la oferta sin asignar nada', () async {
    final r = await ofertas.rechazar('of-3', claveIdempotencia: 'k3');
    expect(r, ResultadoRespuestaOferta.rechazada);
    expect(almacen.asignados.length, 1);
  });

  test('perfil, drones e historial del proveedor tienen datos', () async {
    final perfil = await PerfilDemo(almacen).perfil();
    expect(perfil.tipo, TipoProveedor.propioAgrocom);
    expect(perfil.resenas, isNotEmpty);
    expect((await PerfilDemo(almacen).hectareasPorMes()).length, 6);
    expect((await PerfilDemo(almacen).historial()), isNotEmpty);
    expect((await DronesDemo(almacen).observar().first).length, 2);
  });
}
