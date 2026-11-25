import 'package:agrocom_field/cliente/contactos/data/contactos_demo.dart';
import 'package:agrocom_field/cliente/solicitar/domain/reglas_solicitud.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_estado.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas_solicitar.dart';

void main() {
  late RepositorioEspia repo;
  late SolicitarCubit cubit;

  setUp(() {
    repo = RepositorioEspia();
    cubit = crearCubit(repo);
  });
  tearDown(() => cubit.close());

  test(
    'cargar trae lotes, productos, cultivos y fechas desde mañana',
    () async {
      expect(cubit.state.carga, CargaSolicitud.cargando);
      await cubit.cargar();
      expect(cubit.state.carga, CargaSolicitud.lista);
      expect(cubit.state.lotes, hasLength(5));
      expect(cubit.state.productos, isNotEmpty);
      expect(cubit.state.cultivos, contains('Soya'));
      expect(cubit.state.fechas.first, DateTime(2026, 11, 24));
      expect(cubit.state.puedeAvanzar, isFalse);
    },
  );

  test('si la carga falla queda en error y se puede reintentar', () async {
    repo.fallaLaCarga = true;
    await cubit.cargar();
    expect(cubit.state.carga, CargaSolicitud.error);
    repo.fallaLaCarga = false;
    await cubit.cargar();
    expect(cubit.state.carga, CargaSolicitud.lista);
  });

  test('sin lotes guardados el formulario abre en modo dibujo', () async {
    final vacio = RepositorioEspia(lotes: const []);
    final c = crearCubit(vacio);
    await c.cargar();
    expect(c.state.modoLote, ModoLote.dibujo);
    await c.close();
  });

  test('elegir un lote propone sus hectáreas y su cultivo', () async {
    await cubit.cargar();
    cubit.elegirLote(cubit.state.lotes[1]);
    expect(cubit.state.hectareasTexto, '85,5');
    expect(cubit.state.hectareas, Decimal.parse('85.5'));
    expect(cubit.state.cultivo, 'Maíz');
    expect(cubit.state.puedeAvanzar, isTrue);
  });

  test('dibujar el contorno calcula hectáreas decimales', () async {
    await cubit.cargar();
    cubit.cambiarModoLote(ModoLote.dibujo);
    expect(cubit.state.lote, isNull);
    for (final p in contornoDePrueba.take(2)) {
      cubit.agregarVertice(p);
    }
    expect(
      cubit.state.puedeAvanzar,
      isFalse,
      reason: 'dos esquinas no cierran',
    );
    cubit.agregarVertice(contornoDePrueba[2]);
    expect(cubit.state.puedeAvanzar, isTrue);
    final triangulo = cubit.state.hectareas!;
    cubit.agregarVertice(contornoDePrueba[3]);
    final cuadrado = cubit.state.hectareas!;
    expect(cuadrado, greaterThan(triangulo));
    expect(cuadrado, greaterThan(Decimal.parse('99')));
    expect(cuadrado, lessThan(Decimal.parse('101')));
    expect(cubit.state.lote!.poligono, contornoDePrueba);

    cubit.moverVertice(0, const GeoPunto(-16.9450, -62.6300));
    expect(cubit.state.hectareas, greaterThan(cuadrado));

    cubit.deshacerVertice();
    expect(cubit.state.vertices, hasLength(3));
    cubit.borrarContorno();
    expect(cubit.state.vertices, isEmpty);
    expect(cubit.state.hectareasTexto, isEmpty);
    expect(cubit.state.puedeAvanzar, isFalse);
  });

  test(
    'las hectáreas se pueden editar y un valor inválido no deja seguir',
    () async {
      await cubit.cargar();
      cubit
        ..elegirLote(cubit.state.lotes[1])
        ..elegirProducto('Insecticida piretroide');
      await cubit.avanzar();
      expect(cubit.state.paso, PasoSolicitud.aplicacion);

      cubit.cambiarHectareas('40,25');
      expect(cubit.state.hectareas, Decimal.parse('40.25'));
      expect(cubit.state.puedeAvanzar, isTrue);

      cubit.cambiarHectareas('cuarenta');
      expect(cubit.state.errorHectareas, isNotNull);
      expect(cubit.state.puedeAvanzar, isFalse);
      await cubit.avanzar();
      expect(cubit.state.paso, PasoSolicitud.aplicacion);
    },
  );

  test(
    'un lote registrado no admite pedir más hectáreas que las suyas',
    () async {
      await cubit.cargar();
      cubit
        ..elegirLote(cubit.state.lotes[1])
        ..cambiarHectareas('90');
      expect(cubit.state.errorHectareas, ErrorHectareas.sobreLote);
      expect(cubit.state.hectareas, isNull);
      cubit.cambiarHectareas('85,5');
      expect(cubit.state.errorHectareas, isNull);
    },
  );

  test('cambiar de lote descarta la edición manual de hectáreas', () async {
    await cubit.cargar();
    cubit
      ..elegirLote(cubit.state.lotes[1])
      ..cambiarHectareas('40')
      ..elegirLote(cubit.state.lotes[0]);
    expect(cubit.state.hectareasTexto, '120');
  });

  test('fecha inválida: no se acepta y explica por qué', () async {
    await cubit.cargar();
    cubit.elegirFecha(ahoraDePrueba);
    expect(cubit.state.fecha, isNull);
    expect(cubit.state.errorFecha, isNotNull);

    cubit.elegirFecha(DateTime(2026, 12, 25));
    expect(cubit.state.fecha, isNull);

    cubit.elegirFecha(DateTime(2026, 11, 26, 15, 30));
    expect(cubit.state.fecha, DateTime(2026, 11, 26));
    expect(cubit.state.errorFecha, isNull);
  });

  test('el precio por hectárea es decimal exacto y calcula el total', () async {
    await completarHastaPrecio(cubit);
    expect(cubit.state.paso, PasoSolicitud.precio);
    expect(cubit.state.puedeAvanzar, isFalse, reason: 'falta el precio');
    expect(cubit.state.errorPrecio, isNull, reason: 'no se regaña antes');

    cubit.cambiarPrecio('118,40');
    expect(cubit.state.precio, Decimal.parse('118.4'));
    // 85,5 × 118,4: en double daría 10123.199999999999.
    expect(cubit.state.total, Decimal.parse('10123.2'));
    expect(cubit.state.puedeAvanzar, isTrue);

    cubit.cambiarPrecio('abc');
    expect(cubit.state.errorPrecio, isNotNull);
    expect(cubit.state.puedeAvanzar, isFalse);
    cubit.cambiarPrecio('0');
    expect(cubit.state.errorPrecio, ErrorPrecio.noPositivo);
    cubit.cambiarPrecio('10,555');
    expect(cubit.state.errorPrecio, ErrorPrecio.decimales);
  });

  test('volver atrás conserva lo elegido', () async {
    await completarHastaPrecio(cubit);
    cubit
      ..cambiarPrecio('120')
      ..cambiarObservaciones('Línea eléctrica al sur')
      ..retroceder()
      ..retroceder();
    expect(cubit.state.paso, PasoSolicitud.aplicacion);
    expect(cubit.state.avanza, isFalse);
    expect(cubit.state.producto, 'Insecticida piretroide');
    expect(cubit.state.fecha, DateTime(2026, 11, 26));
    expect(cubit.state.precioTexto, '120');
    expect(cubit.state.observaciones, 'Línea eléctrica al sur');
  });

  test('pedir para mañana marca la solicitud como urgente', () async {
    await completarHastaPrecio(cubit, urgente: true);
    expect(cubit.fechaUrgente, isTrue);
  });

  test('doble envío: una sola solicitud publicada', () async {
    await completarHastaPrecio(cubit);
    cubit
      ..cambiarPrecio('120')
      ..cambiarObservaciones('  Línea eléctrica al sur  ');
    final antes = repo.almacen.solicitudes.length;
    // Dos toques seguidos sobre «Publicar solicitud».
    final primero = cubit.avanzar();
    final segundo = cubit.avanzar();
    expect(cubit.state.enviando, isTrue);
    await Future.wait([primero, segundo]);

    expect(repo.clavesEnviadas, ['clave-1']);
    expect(repo.almacen.solicitudes.length, antes + 1);
    final solicitud = cubit.state.solicitud!;
    expect(solicitud.estado, EstadoSolicitud.abierta);
    expect(solicitud.hectareas, Decimal.parse('85.5'));
    expect(solicitud.precioHaPropuesto, Decimal.fromInt(120));
    expect(solicitud.totalEstimado, Decimal.parse('10260'));
    expect(solicitud.observaciones, 'Línea eléctrica al sur');

    // Un tercer toque, ya publicada, tampoco envía.
    await cubit.publicar();
    expect(repo.clavesEnviadas, hasLength(1));
  });

  test('la solicitud publicada aparece abierta y sin ofertas', () async {
    await completarHastaPrecio(cubit);
    cubit.cambiarPrecio('120');
    await cubit.avanzar();
    final guardada = repo.almacen.porId(cubit.state.solicitud!.id)!;
    expect(guardada.estado, EstadoSolicitud.abierta);
    expect(guardada.ofertasVigentes, 0);
    expect(repo.almacen.ofertasDe(guardada.id), isEmpty);
  });

  test(
    'sin red conserva el formulario y el reintento usa la misma clave',
    () async {
      await completarHastaPrecio(cubit);
      cubit
        ..cambiarHectareas('60')
        ..cambiarPrecio('125');
      final antes = repo.almacen.solicitudes.length;
      repo.demo.sinConexion = true;
      await cubit.publicar();

      expect(cubit.state.falloEnvio, FalloEnvio.sinConexion);
      expect(cubit.state.enviando, isFalse);
      expect(cubit.state.solicitud, isNull);
      expect(cubit.state.paso, PasoSolicitud.precio);
      expect(cubit.state.hectareasTexto, '60');
      expect(cubit.state.precioTexto, '125');
      expect(cubit.state.producto, 'Insecticida piretroide');
      expect(cubit.state.fecha, DateTime(2026, 11, 26));
      expect(cubit.state.loteGuardado!.nombre, 'Maíz La Curva');
      expect(repo.almacen.solicitudes.length, antes);

      repo.demo.sinConexion = false;
      await cubit.avanzar();
      expect(cubit.state.falloEnvio, isNull);
      expect(cubit.state.solicitud, isNotNull);
      expect(repo.clavesEnviadas, ['clave-1', 'clave-1']);
      expect(repo.almacen.solicitudes.length, antes + 1);
      expect(cubit.state.solicitud!.hectareas, Decimal.fromInt(60));
    },
  );

  test('un lote dibujado viaja con su contorno y sus hectáreas', () async {
    await cubit.cargar();
    cubit.cambiarModoLote(ModoLote.dibujo);
    contornoDePrueba.forEach(cubit.agregarVertice);
    await cubit.avanzar();
    cubit
      ..elegirCultivo('Soya')
      ..elegirProducto('Fertilizante foliar');
    await cubit.avanzar();
    cubit
      ..elegirFecha(cubit.state.fechas[3])
      ..cambiarAccesos('Portón azul');
    await cubit.avanzar();
    cubit.cambiarPrecio('100');
    await cubit.avanzar();
    final solicitud = cubit.state.solicitud!;
    expect(solicitud.lote.poligono, contornoDePrueba);
    expect(solicitud.cultivo, 'Soya');
    expect(solicitud.hectareas, hectareasDePoligono(contornoDePrueba));
    expect(solicitud.accesos, 'Portón azul');
  });

  group('contacto de una empresa', () {
    test(
      'un cliente empresa publica con el contacto principal por defecto',
      () async {
        final empresa = SolicitarCubit(
          repo,
          contactos: ContactosDemo(),
          reloj: relojDePrueba,
          claveIdempotencia: 'clave-e',
        );
        await completarHastaPrecio(empresa);
        expect(empresa.state.contactos, hasLength(2));
        expect(empresa.state.contactoId, 1);
        empresa.cambiarPrecio('120');
        await empresa.avanzar();
        expect(repo.enviadas.single.contactoId, 1);
        await empresa.close();
      },
    );

    test('elegir otra persona la envía como contacto_id', () async {
      final empresa = SolicitarCubit(
        repo,
        contactos: ContactosDemo(),
        reloj: relojDePrueba,
        claveIdempotencia: 'clave-e2',
      );
      await completarHastaPrecio(empresa);
      empresa.elegirContacto(2);
      empresa.cambiarPrecio('120');
      await empresa.avanzar();
      expect(repo.enviadas.single.contactoId, 2);
      await empresa.close();
    });

    test('una persona (sin contactos) no envía contacto_id', () async {
      await completarHastaPrecio(cubit);
      expect(cubit.state.contactos, isEmpty);
      cubit.cambiarPrecio('120');
      await cubit.avanzar();
      expect(repo.enviadas.single.contactoId, isNull);
    });
  });
}
