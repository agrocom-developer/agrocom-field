import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/data/estado_red_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/domain/ofertas_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/presentation/ofertas_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/presentation/ofertas_estado.dart';

/// Repositorio que anota cada llamada y deja decidir qué responde.
class _OfertasEspia implements OfertasRepositorio {
  _OfertasEspia(this._base);

  final OfertasRepositorio _base;
  final claves = <String>[];
  Object? fallo;
  Completer<void>? espera;
  bool fallaLectura = false;

  @override
  Stream<List<Oferta>> observar() =>
      fallaLectura ? Stream.error(StateError('sin bandeja')) : _base.observar();

  @override
  Future<ResultadoRespuestaOferta> aceptar(
    String ofertaId, {
    required String claveIdempotencia,
  }) async {
    claves.add(claveIdempotencia);
    await espera?.future;
    if (fallo != null) throw fallo!;
    return _base.aceptar(ofertaId, claveIdempotencia: claveIdempotencia);
  }

  @override
  Future<ResultadoRespuestaOferta> rechazar(
    String ofertaId, {
    required String claveIdempotencia,
  }) async {
    claves.add(claveIdempotencia);
    if (fallo != null) throw fallo!;
    return _base.rechazar(ofertaId, claveIdempotencia: claveIdempotencia);
  }
}

void main() {
  var ahora = DateTime(2026, 11, 23, 9);
  late AlmacenDemoProveedor almacen;
  late _OfertasEspia repo;
  late OfertasCubit cubit;
  var claves = 0;

  Future<void> asentar() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    ahora = DateTime(2026, 11, 23, 9);
    claves = 0;
    almacen = AlmacenDemoProveedor(datos: DatosDemo(reloj: () => ahora));
    repo = _OfertasEspia(OfertasDemo(almacen, latencia: Duration.zero));
    cubit = OfertasCubit(
      repositorio: repo,
      estadoRed: EstadoRedDemo(almacen),
      reloj: () => ahora,
      nuevaClave: () => 'clave-${++claves}',
      pulso: null,
    );
  });

  tearDown(() => cubit.close());

  test('arranca cargando y lista las ofertas por vencimiento', () async {
    expect(cubit.state.carga, CargaOfertas.cargando);
    cubit.iniciar();
    await asentar();
    expect(cubit.state.carga, CargaOfertas.lista);
    expect(cubit.state.enLinea, isTrue);
    // of-1 vence en 3 min; of-2 en 8; of-3 en 10.
    expect(cubit.state.ofertas.map((o) => o.id), ['of-1', 'of-2', 'of-3']);
  });

  test(
    'la cuenta regresiva avanza con el reloj, no con el dispositivo',
    () async {
      cubit.iniciar();
      await asentar();
      final o = cubit.state.vigente('of-1')!;
      expect(o.restante(cubit.state.ahora), const Duration(minutes: 3));
      ahora = ahora.add(const Duration(seconds: 50));
      cubit.tic();
      expect(o.restante(cubit.state.ahora), const Duration(seconds: 130));
    },
  );

  test(
    'una oferta cuya ventana se agota pasa a vencida una sola vez',
    () async {
      cubit.iniciar();
      await asentar();
      ahora = ahora.add(const Duration(minutes: 3));
      cubit.tic();
      cubit.tic();
      expect(cubit.state.vigente('of-1'), isNull);
      expect(cubit.state.cerradas, hasLength(1));
      expect(cubit.state.cerrada('of-1')!.motivo, MotivoCierreOferta.vencida);

      cubit.descartar('of-1');
      cubit.tic();
      expect(cubit.state.cerradas, isEmpty);
    },
  );

  test('aceptar quita la oferta, avisa y deja el servicio asignado', () async {
    cubit.iniciar();
    await asentar();
    await cubit.aceptar('of-1');
    expect(cubit.state.vigente('of-1'), isNull);
    expect(cubit.state.cerradas, isEmpty);
    expect(cubit.state.respondiendo, isEmpty);
    expect(cubit.state.aviso!.resultado, ResultadoRespuestaOferta.aceptada);
    expect(almacen.asignados, hasLength(2));
  });

  test('mientras la respuesta viaja la oferta queda en espera', () async {
    cubit.iniciar();
    await asentar();
    repo.espera = Completer<void>();
    final respuesta = cubit.aceptar('of-1');
    await asentar();
    expect(cubit.state.respondiendo, {'of-1'});

    // Un segundo toque no dispara otra respuesta.
    await cubit.aceptar('of-1');
    await cubit.rechazar('of-1');
    expect(repo.claves, hasLength(1));

    repo.espera!.complete();
    await respuesta;
    expect(cubit.state.respondiendo, isEmpty);
  });

  test(
    'si otro proveedor la tomó antes queda como tomada, sin error',
    () async {
      cubit.iniciar();
      await asentar();
      await cubit.aceptar(ofertaPerdidaEnDemo);
      await asentar();
      expect(cubit.state.vigente(ofertaPerdidaEnDemo), isNull);
      expect(
        cubit.state.cerrada(ofertaPerdidaEnDemo)!.motivo,
        MotivoCierreOferta.tomada,
      );
      expect(cubit.state.aviso!.resultado, ResultadoRespuestaOferta.perdida);
      expect(almacen.asignados, hasLength(1));
    },
  );

  test('rechazar quita la oferta sin dejarla como cerrada', () async {
    cubit.iniciar();
    await asentar();
    await cubit.rechazar('of-3');
    expect(cubit.state.vigente('of-3'), isNull);
    expect(cubit.state.cerradas, isEmpty);
    expect(cubit.state.aviso!.resultado, ResultadoRespuestaOferta.rechazada);
  });

  test(
    'sin red no llama al servidor y la oferta sigue en la bandeja',
    () async {
      cubit.iniciar();
      await asentar();
      almacen.enLinea = false;
      await asentar();
      expect(cubit.state.enLinea, isFalse);

      await cubit.aceptar('of-1');
      expect(repo.claves, isEmpty);
      expect(cubit.state.vigente('of-1'), isNotNull);
      expect(
        cubit.state.aviso!.resultado,
        ResultadoRespuestaOferta.sinConexion,
      );

      // Dos avisos iguales seguidos se distinguen por su número.
      final primero = cubit.state.aviso!.numero;
      await cubit.aceptar('of-1');
      expect(cubit.state.aviso!.numero, isNot(primero));

      almacen.enLinea = true;
      await asentar();
      await cubit.aceptar('of-1');
      expect(cubit.state.aviso!.resultado, ResultadoRespuestaOferta.aceptada);
    },
  );

  test(
    'una respuesta perdida se reintenta con la misma clave de idempotencia',
    () async {
      cubit.iniciar();
      await asentar();
      repo.fallo = TimeoutException('sin respuesta');
      await cubit.aceptar('of-1');
      expect(
        cubit.state.aviso!.resultado,
        ResultadoRespuestaOferta.sinConexion,
      );
      expect(cubit.state.vigente('of-1'), isNotNull);
      expect(cubit.state.respondiendo, isEmpty);

      repo.fallo = null;
      await cubit.aceptar('of-1');
      expect(repo.claves, ['clave-1', 'clave-1']);
      expect(cubit.state.aviso!.resultado, ResultadoRespuestaOferta.aceptada);
      expect(almacen.asignados, hasLength(2));
    },
  );

  test('cada oferta lleva su propia clave', () async {
    cubit.iniciar();
    await asentar();
    await cubit.rechazar('of-1');
    await cubit.rechazar('of-3');
    expect(repo.claves, ['clave-1', 'clave-2']);
  });

  test('un error de lectura se puede reintentar', () async {
    repo.fallaLectura = true;
    cubit.iniciar();
    await asentar();
    expect(cubit.state.carga, CargaOfertas.error);

    repo.fallaLectura = false;
    cubit.reintentar();
    expect(cubit.state.carga, CargaOfertas.cargando);
    await asentar();
    expect(cubit.state.carga, CargaOfertas.lista);
    expect(cubit.state.ofertas, hasLength(3));
  });

  test('con el pulso activo la cuenta regresiva avanza sola', () async {
    final conPulso = OfertasCubit(
      repositorio: repo,
      estadoRed: EstadoRedDemo(almacen),
      reloj: () => ahora,
      pulso: const Duration(milliseconds: 5),
    )..iniciar();
    await asentar();
    ahora = ahora.add(const Duration(seconds: 7));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(conPulso.state.ahora, ahora);
    await conPulso.close();
  });
}
