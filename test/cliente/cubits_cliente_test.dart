import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/calificar/data/calificacion_demo.dart';
import 'package:agrocom_field/cliente/calificar/presentation/calificar_cubit.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/cliente/ofertas/domain/comparador_ofertas.dart';
import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/ofertas/presentation/ofertas_cubit.dart';
import 'package:agrocom_field/cliente/problema/data/problema_demo.dart';
import 'package:agrocom_field/cliente/problema/presentation/reportar_problema_cubit.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_cubit.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_cubit.dart';
import 'package:agrocom_field/cliente/solicitudes/data/solicitudes_demo.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/historial_cubit.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/solicitud_detalle_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

/// Solicitudes de la demo (ver `AlmacenDemoCliente`): 4101 con tres ofertas,
/// 4102 en ejecución, 4103 finalizada sin calificar, 4104 calificada y 4105
/// expirada.
void main() {
  final ahora = DateTime(2026, 11, 23, 9);
  late AlmacenDemoCliente almacen;

  setUp(() {
    almacen = AlmacenDemoCliente(datos: DatosDemo(reloj: () => ahora));
  });

  Future<void> vaciarCola() => Future<void>.delayed(Duration.zero);

  group('CalificarCubit', () {
    CalificarCubit crear() => CalificarCubit(
      CalificacionDemo(almacen, latencia: Duration.zero),
      '4103',
    );

    test('sin estrella no se puede enviar', () async {
      final cubit = crear();
      expect(cubit.state.puedeEnviar, isFalse);
      await cubit.enviar();
      expect(cubit.state.fase, FaseCalificar.editando);
      expect(almacen.porId('4103')!.puntajeDelCliente, isNull);
    });

    blocTest<CalificarCubit, CalificarEstado>(
      'dos toques alcanzan: estrella y enviar; la solicitud queda calificada',
      build: crear,
      act: (c) async {
        c.elegirPuntaje(5);
        await c.enviar();
      },
      expect: () => [
        isA<CalificarEstado>().having((e) => e.puntaje, 'puntaje', 5),
        isA<CalificarEstado>().having(
          (e) => e.fase,
          'fase',
          FaseCalificar.enviando,
        ),
        isA<CalificarEstado>().having(
          (e) => e.fase,
          'fase',
          FaseCalificar.enviada,
        ),
      ],
      verify: (_) {
        expect(almacen.porId('4103')!.puntajeDelCliente, 5);
        expect(almacen.porId('4103')!.estado, EstadoSolicitud.calificada);
      },
    );

    test('las etiquetas se alternan y viajan con el comentario', () async {
      final cubit = crear()
        ..elegirPuntaje(4)
        ..alternarEtiqueta(EtiquetaCalificacion.puntualidad)
        ..alternarEtiqueta(EtiquetaCalificacion.ordenEnElLote)
        ..alternarEtiqueta(EtiquetaCalificacion.puntualidad)
        ..cambiarComentario('  Dejaron todo limpio.  ');
      expect(cubit.state.etiquetas, {EtiquetaCalificacion.ordenEnElLote});
      await cubit.enviar();
      final guardada = almacen.calificaciones['4103']!;
      expect(guardada.etiquetas, {EtiquetaCalificacion.ordenEnElLote});
      expect(guardada.comentario, 'Dejaron todo limpio.');
    });

    test(
      'sin red queda en error, conserva lo elegido y permite reintentar',
      () async {
        almacen.sinRed = true;
        final cubit = crear()..elegirPuntaje(3);
        await cubit.enviar();
        expect(cubit.state.fase, FaseCalificar.error);
        expect(cubit.state.sinConexion, isTrue);
        expect(cubit.state.puntaje, 3);
        almacen.sinRed = false;
        await cubit.enviar();
        expect(cubit.state.fase, FaseCalificar.enviada);
        expect(almacen.porId('4103')!.puntajeDelCliente, 3);
      },
    );
  });

  group('HistorialCubit', () {
    test('carga, filtra y resume las hectáreas en decimal exacto', () async {
      final cubit = HistorialCubit(SolicitudesDemo(almacen));
      expect(cubit.state.fase, FaseHistorial.cargando);
      await vaciarCola();
      expect(cubit.state.fase, FaseHistorial.listo);
      expect(cubit.state.visibles, hasLength(5));
      expect(cubit.state.totalCompletados, 2);
      // 64 (girasol) + 210 (trigo).
      expect(cubit.state.hectareasFumigadas, Decimal.parse('274'));

      cubit.filtrar(FiltroHistorial.activos);
      expect(
        cubit.state.visibles.map((s) => s.estado.activa),
        everyElement(isTrue),
      );
      expect(cubit.state.visibles, hasLength(3));
      cubit.filtrar(FiltroHistorial.completados);
      expect(cubit.state.visibles.map((s) => s.id), ['4103', '4104']);
      await cubit.close();
    });

    test('reparte las hectáreas por mes, con ceros donde no hubo', () async {
      final cubit = HistorialCubit(SolicitudesDemo(almacen));
      await vaciarCola();
      final meses = cubit.state.hectareasPorMes(hasta: ahora);
      expect(meses, hasLength(6));
      expect(meses.first.mes, DateTime(2026, 6));
      expect(meses.last.mes, DateTime(2026, 11));
      expect(meses.last.hectareas, Decimal.parse('274'));
      expect(meses[0].hectareas, Decimal.zero);
      await cubit.close();
    });

    test('el gráfico cruza bien el cambio de año', () {
      const estado = HistorialEstado(fase: FaseHistorial.listo);
      final meses = estado.hectareasPorMes(hasta: DateTime(2027, 2, 10));
      expect(meses.first.mes, DateTime(2026, 9));
      expect(meses.last.mes, DateTime(2027, 2));
    });

    test('sin red queda en error y reintentar lo recupera', () async {
      almacen.sinRed = true;
      final cubit = HistorialCubit(SolicitudesDemo(almacen));
      await vaciarCola();
      expect(cubit.state.fase, FaseHistorial.error);
      expect(cubit.state.sinConexion, isTrue);
      almacen.sinRed = false;
      cubit.reintentar();
      expect(cubit.state.fase, FaseHistorial.cargando);
      await vaciarCola();
      expect(cubit.state.fase, FaseHistorial.listo);
      await cubit.close();
    });

    test('una calificación nueva llega sola al historial', () async {
      final cubit = HistorialCubit(SolicitudesDemo(almacen));
      await vaciarCola();
      await CalificacionDemo(
        almacen,
        latencia: Duration.zero,
      ).calificarProveedor(servicioId: '4103', puntaje: 5);
      await vaciarCola();
      final s = cubit.state.servicios.firstWhere((s) => s.id == '4103');
      expect(s.puntajeDelCliente, 5);
      expect(s.estado, EstadoSolicitud.calificada);
      await cubit.close();
    });
  });

  group('ReportarProblemaCubit', () {
    ReportarProblemaCubit crear() => ReportarProblemaCubit(
      ProblemaDemo(almacen, latencia: Duration.zero),
      servicioId: '4103',
      claveIdempotencia: 'clave-problema',
    );

    test('exige motivo y un detalle de al menos diez caracteres', () async {
      final cubit = crear();
      expect(cubit.state.puedeEnviar, isFalse);
      cubit.elegirMotivo(MotivoProblema.coberturaIncompleta);
      expect(cubit.state.puedeEnviar, isFalse);
      cubit.cambiarDetalle('   corto   ');
      expect(cubit.state.puedeEnviar, isFalse);
      await cubit.enviar();
      expect(almacen.problemas, isEmpty);
      cubit.cambiarDetalle('Faltó el borde norte del lote.');
      expect(cubit.state.puedeEnviar, isTrue);
    });

    test('envía, devuelve el caso y la solicitud queda en reclamo', () async {
      final cubit = crear()
        ..elegirMotivo(MotivoProblema.coberturaIncompleta)
        ..cambiarDetalle('  Faltó el borde norte del lote.  ');
      await cubit.enviar();
      expect(cubit.state.fase, FaseReporte.enviado);
      expect(cubit.state.caso!.numeroCaso, 'C-2041');
      expect(cubit.state.caso!.detalle, 'Faltó el borde norte del lote.');
      expect(almacen.porId('4103')!.estado, EstadoSolicitud.disputada);
    });

    test(
      'sin red conserva el formulario; el reintento no duplica el caso',
      () async {
        almacen.sinRed = true;
        final cubit = crear()
          ..elegirMotivo(MotivoProblema.danoCultivos)
          ..cambiarDetalle('Deriva sobre el lote vecino.');
        await cubit.enviar();
        expect(cubit.state.fase, FaseReporte.error);
        expect(cubit.state.sinConexion, isTrue);
        almacen.sinRed = false;
        await cubit.enviar();
        await cubit.enviar();
        expect(cubit.state.fase, FaseReporte.enviado);
        expect(almacen.problemas, hasLength(1));
      },
    );
  });

  group('SolicitudDetalleCubit', () {
    SolicitudDetalleCubit crear(String id) => SolicitudDetalleCubit(
      solicitudes: SolicitudesDemo(almacen, latencia: Duration.zero),
      problemas: ProblemaDemo(almacen, latencia: Duration.zero),
      calificaciones: CalificacionDemo(almacen, latencia: Duration.zero),
      solicitudId: id,
    );

    test('carga la solicitud y arma su línea de tiempo', () async {
      final cubit = crear('4102');
      expect(cubit.state.fase, FaseDetalle.cargando);
      await vaciarCola();
      expect(cubit.state.fase, FaseDetalle.listo);
      expect(cubit.state.solicitud!.estado, EstadoSolicitud.enEjecucion);
      final actual = cubit.state.hitos.where(
        (h) => h.estado == EstadoHito.actual,
      );
      expect(actual.single.clave, 'ejecucion');
      await cubit.close();
    });

    test('un id desconocido queda en no encontrado', () async {
      final cubit = crear('9999');
      await vaciarCola();
      expect(cubit.state.fase, FaseDetalle.noEncontrado);
      await cubit.close();
    });

    test(
      'cambiar el precio actualiza la solicitud mientras se negocia',
      () async {
        final cubit = crear('4101');
        await vaciarCola();
        expect(await cubit.cambiarPrecio(Decimal.parse('118')), isTrue);
        await vaciarCola();
        expect(cubit.state.solicitud!.precioHaPropuesto, Decimal.parse('118'));
        await cubit.close();
      },
    );

    test('cancelar con motivo cierra la solicitud', () async {
      final cubit = crear('4101');
      await vaciarCola();
      expect(await cubit.cancelar('Cambió la fecha'), isTrue);
      await vaciarCola();
      expect(cubit.state.solicitud!.estado, EstadoSolicitud.cancelada);
      await cubit.close();
    });

    test('renovar vuelve a abrir una solicitud expirada', () async {
      final cubit = crear('4105');
      await vaciarCola();
      expect(cubit.state.solicitud!.estado, EstadoSolicitud.expirada);
      expect(await cubit.renovar(), isTrue);
      await vaciarCola();
      expect(cubit.state.solicitud!.estado, EstadoSolicitud.abierta);
      await cubit.close();
    });

    test(
      'sin red la acción falla, no cambia nada y se puede reintentar',
      () async {
        final cubit = crear('4101');
        await vaciarCola();
        almacen.sinRed = true;
        expect(await cubit.cambiarPrecio(Decimal.parse('99')), isFalse);
        expect(cubit.state.fallo, FalloAccion.sinConexion);
        expect(cubit.state.enCurso, isFalse);
        expect(almacen.porId('4101')!.precioHaPropuesto, Decimal.parse('110'));
        almacen.sinRed = false;
        expect(await cubit.cambiarPrecio(Decimal.parse('99')), isTrue);
        await cubit.close();
      },
    );

    test('al terminar carga su calificación y su reclamo', () async {
      final cubit = crear('4103');
      await vaciarCola();
      await vaciarCola();
      expect(cubit.state.problema, isNull);
      expect(cubit.state.anexosIncompletos, isFalse);
      await CalificacionDemo(
        almacen,
        latencia: Duration.zero,
      ).calificarProveedor(servicioId: '4103', puntaje: 4);
      await cubit.recargarAnexos();
      expect(cubit.state.calificacion?.puntaje, 4);
      await cubit.close();
    });
  });

  group('OfertasCubit', () {
    OfertasCubit crear({String id = '4101'}) => OfertasCubit(
      ofertas: OfertasDemo(almacen, latencia: Duration.zero),
      solicitudes: SolicitudesDemo(almacen, latencia: Duration.zero),
      solicitudId: id,
      intervalo: null,
    );

    test('carga las ofertas vigentes en el orden recomendado', () async {
      final cubit = crear();
      expect(cubit.state.fase, FaseOfertas.cargando);
      await cubit.cargar();
      expect(cubit.state.fase, FaseOfertas.lista);
      expect(cubit.state.orden, OrdenOfertas.recomendado);
      expect(cubit.state.vigentes(ahora).map((o) => o.precioHa), [
        Decimal.parse('110'),
        Decimal.parse('121'),
        Decimal.parse('104'),
      ]);
      await cubit.ordenar(OrdenOfertas.precio);
      expect(cubit.state.vigentes(ahora).map((o) => o.precioHa), [
        Decimal.parse('104'),
        Decimal.parse('110'),
        Decimal.parse('121'),
      ]);
      await cubit.close();
    });

    test('se pueden ordenar por calificación y por lo más reciente', () async {
      final cubit = crear();
      await cubit.cargar();
      await cubit.ordenar(OrdenOfertas.calificacion);
      expect(cubit.state.vigentes(ahora).map((o) => o.proveedor.calificacion), [
        4.9,
        4.8,
        4.7,
      ]);
      await cubit.ordenar(OrdenOfertas.reciente);
      expect(cubit.state.orden, OrdenOfertas.reciente);
      final fechas = cubit.state
          .vigentes(ahora)
          .map((o) => o.creadaEn!)
          .toList();
      expect(fechas, hasLength(3));
      expect(fechas, [...fechas]..sort((a, b) => b.compareTo(a)));
      await cubit.close();
    });

    test('elegir una oferta adjudica y cierra las demás', () async {
      final cubit = crear();
      await cubit.cargar();
      final elegida = cubit.state.ofertas.firstWhere(
        (o) => o.id == 'of-4101-a',
      );
      await cubit.aceptar(elegida);
      expect(cubit.state.adjudicada, isTrue);
      expect(cubit.state.respondiendo, isNull);
      final s = almacen.porId('4101')!;
      expect(s.estado, EstadoSolicitud.adjudicada);
      expect(s.precioHaAcordado, Decimal.parse('110'));
      expect(s.nombreProveedor, elegida.proveedor.nombre);
      final estados = {
        for (final o in almacen.ofertasDe('4101')) o.id: o.estado,
      };
      expect(estados['of-4101-a'], EstadoOferta.aceptada);
      expect(estados['of-4101-b'], EstadoOferta.cerrada);
      expect(estados['of-4101-c'], EstadoOferta.cerrada);
      await cubit.close();
    });

    test(
      'contraofertar abre la ronda siguiente con el cliente como autor',
      () async {
        final cubit = crear();
        await cubit.cargar();
        final oferta = cubit.state.ofertas.firstWhere(
          (o) => o.id == 'of-4101-b',
        );
        await cubit.contraofertar(
          oferta,
          Decimal.parse('107'),
          nota: 'Mi tope',
        );
        expect(cubit.state.aviso, AvisoOfertas.contraofertaEnviada);
        final nueva = cubit.state
            .vigentes(ahora)
            .firstWhere((o) => o.autor == AutorOferta.cliente);
        expect(nueva.numero, 2);
        expect(nueva.precioHa, Decimal.parse('107'));
        expect(nueva.esperaAlPiloto(ahora), isTrue);
        expect(
          cubit.state.cerradas(ahora).map((o) => o.id),
          contains('of-4101-b'),
        );
        await cubit.close();
      },
    );

    test('rechazar cierra esa oferta y deja las demás', () async {
      final cubit = crear();
      await cubit.cargar();
      await cubit.rechazar(
        cubit.state.ofertas.firstWhere((o) => o.id == 'of-4101-c'),
      );
      expect(cubit.state.aviso, AvisoOfertas.rechazada);
      expect(cubit.state.vigentes(ahora), hasLength(2));
      await cubit.close();
    });

    test('una oferta que cambió se explica y recarga la lista', () async {
      final cubit = crear();
      await cubit.cargar();
      final vieja = cubit.state.ofertas.firstWhere((o) => o.id == 'of-4101-a');
      // El piloto la retiró mientras el cliente decidía.
      almacen.rechazarOferta(vieja);
      await cubit.aceptar(vieja);
      expect(cubit.state.aviso, AvisoOfertas.cambio);
      expect(cubit.state.mensajeAviso, contains('ya no está vigente'));
      expect(cubit.state.adjudicada, isFalse);
      expect(
        cubit.state.vigentes(ahora).map((o) => o.id),
        isNot(contains(vieja.id)),
      );
      await cubit.close();
    });

    test(
      'si otra oferta ya se adjudicó, no se puede elegir una segunda',
      () async {
        final cubit = crear();
        await cubit.cargar();
        final a = cubit.state.ofertas.firstWhere((o) => o.id == 'of-4101-a');
        final b = cubit.state.ofertas.firstWhere((o) => o.id == 'of-4101-b');
        await cubit.aceptar(a);
        await cubit.aceptar(b);
        expect(cubit.state.aviso, AvisoOfertas.cambio);
        expect(almacen.porId('4101')!.ofertaAdjudicadaId, 'of-4101-a');
        await cubit.close();
      },
    );

    test('sin red avisa y deja las ofertas como estaban', () async {
      final cubit = crear();
      await cubit.cargar();
      final oferta = cubit.state.ofertas.first;
      almacen.sinRed = true;
      await cubit.aceptar(oferta);
      expect(cubit.state.aviso, AvisoOfertas.sinConexion);
      expect(cubit.state.respondiendo, isNull);
      expect(cubit.state.adjudicada, isFalse);
      expect(cubit.state.ofertas, hasLength(3));
      await cubit.close();
    });

    test('sin red al abrir queda en error con el motivo', () async {
      almacen.sinRed = true;
      final cubit = crear();
      await cubit.cargar();
      expect(cubit.state.fase, FaseOfertas.error);
      expect(cubit.state.sinConexion, isTrue);
      almacen.sinRed = false;
      await cubit.cargar();
      expect(cubit.state.fase, FaseOfertas.lista);
      await cubit.close();
    });

    test('una solicitud desconocida queda en no encontrada', () async {
      final cubit = crear(id: '9999');
      await cubit.cargar();
      expect(cubit.state.fase, FaseOfertas.noEncontrada);
      await cubit.close();
    });

    test(
      'el piloto simulado responde la contraoferta con el punto medio',
      () async {
        final automatico = AlmacenDemoCliente(
          datos: DatosDemo(reloj: () => ahora),
          respuestasAutomaticas: true,
          espera: const Duration(milliseconds: 5),
        );
        final cubit = OfertasCubit(
          ofertas: OfertasDemo(automatico, latencia: Duration.zero),
          solicitudes: SolicitudesDemo(automatico, latencia: Duration.zero),
          solicitudId: '4101',
          intervalo: null,
        );
        await cubit.cargar();
        final oferta = cubit.state.ofertas.firstWhere(
          (o) => o.id == 'of-4101-c',
        );
        await cubit.contraofertar(oferta, Decimal.parse('101'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await cubit.actualizar();
        final respuesta = cubit.state
            .vigentes(ahora)
            .firstWhere((o) => o.numero == 3);
        expect(respuesta.autor, AutorOferta.proveedor);
        expect(respuesta.precioHa, Decimal.parse('111'));
        await cubit.close();
        automatico.cerrar();
      },
    );
  });

  group('SeguimientoCubit', () {
    SeguimientoCubit crear(String id) => SeguimientoCubit(
      seguimiento: SeguimientoDemo(almacen, latencia: Duration.zero),
      solicitudes: SolicitudesDemo(almacen, latencia: Duration.zero),
      solicitudId: id,
      intervalo: null,
    );

    test('en ejecución trae el avance, las fotos y la ubicación', () async {
      final cubit = crear('4102');
      await cubit.cargar();
      expect(cubit.state.fase, FaseSeguimiento.listo);
      expect(cubit.state.avance!.porcentaje, Decimal.parse('60.82'));
      expect(cubit.state.avance!.fotos, hasLength(2));
      expect(cubit.state.ubicacion, isNotNull);
      expect(cubit.state.ubicacion!.vigente, isTrue);
      await cubit.close();
    });

    test('una solicitud terminada no muestra ubicación', () async {
      final cubit = crear('4103');
      await cubit.cargar();
      expect(cubit.state.ubicacion, isNull);
      expect(cubit.state.avance!.progreso, 1.0);
      await cubit.close();
    });

    test('sin red conserva lo último que llegó', () async {
      final cubit = crear('4102');
      await cubit.cargar();
      almacen.sinRed = true;
      await cubit.actualizar();
      expect(cubit.state.fase, FaseSeguimiento.listo);
      expect(cubit.state.sinConexion, isTrue);
      expect(cubit.state.avance, isNotNull);
      almacen.sinRed = false;
      await cubit.actualizar();
      expect(cubit.state.sinConexion, isFalse);
      await cubit.close();
    });

    test('sin red y sin datos queda en error', () async {
      almacen.sinRed = true;
      final cubit = crear('4102');
      await cubit.cargar();
      expect(cubit.state.fase, FaseSeguimiento.error);
      expect(cubit.state.sinConexion, isTrue);
      await cubit.close();
    });

    test('una solicitud ajena no se encuentra', () async {
      final cubit = crear('9999');
      await cubit.cargar();
      expect(cubit.state.fase, FaseSeguimiento.noEncontrado);
      await cubit.close();
    });
  });

  group('ChatCubit', () {
    ChatCubit crear({String id = '4102'}) => ChatCubit(
      repositorio: SeguimientoDemo(almacen, latencia: Duration.zero),
      solicitudId: id,
      intervalo: null,
    );

    test('carga los mensajes en orden y distingue los propios', () async {
      final cubit = crear();
      await cubit.cargar();
      expect(cubit.state.fase, FaseChat.lista);
      expect(cubit.state.mensajes.map((m) => m.propio), [false, true]);
      expect(cubit.state.soloLectura, isFalse);
      await cubit.close();
    });

    test('enviar agrega el mensaje y no lo duplica al volver a leer', () async {
      final cubit = crear();
      await cubit.cargar();
      expect(await cubit.enviar('  Llego a las 7  '), isTrue);
      expect(cubit.state.mensajes.last.texto, 'Llego a las 7');
      expect(cubit.state.mensajes.last.propio, isTrue);
      await cubit.actualizar();
      expect(cubit.state.mensajes.map((m) => m.texto).toSet(), hasLength(3));
      await cubit.close();
    });

    test('un mensaje vacío no sale', () async {
      final cubit = crear();
      await cubit.cargar();
      expect(await cubit.enviar('   '), isFalse);
      expect(cubit.state.mensajes, hasLength(2));
      await cubit.close();
    });

    test(
      'sin red conserva el texto y el reintento usa la misma clave',
      () async {
        final cubit = crear();
        await cubit.cargar();
        almacen.sinRed = true;
        expect(await cubit.enviar('Hola'), isFalse);
        expect(cubit.state.fallo, FalloMensaje.sinConexion);
        expect(cubit.state.enviando, isFalse);
        almacen.sinRed = false;
        expect(await cubit.enviar('Hola'), isTrue);
        expect(await cubit.enviar('Hola'), isTrue);
        final propios = almacen
            .mensajesDe('4102')
            .where((m) => m.texto == 'Hola');
        // Dos envíos del mismo texto tras un éxito son dos mensajes distintos;
        // el reintento tras el fallo no creó uno de más.
        expect(propios, hasLength(2));
        await cubit.close();
      },
    );

    test('con el chat cerrado se puede leer pero no escribir', () async {
      final cubit = crear(id: '4104');
      await cubit.cargar();
      expect(cubit.state.soloLectura, isTrue);
      expect(await cubit.enviar('Gracias'), isFalse);
      await cubit.close();
    });

    test('sin red al abrir queda en error y cargar lo recupera', () async {
      almacen.sinRed = true;
      final cubit = crear();
      await cubit.cargar();
      expect(cubit.state.fase, FaseChat.error);
      almacen.sinRed = false;
      await cubit.cargar();
      expect(cubit.state.fase, FaseChat.lista);
      await cubit.close();
    });
  });

  group('línea de tiempo', () {
    Solicitud con(EstadoSolicitud estado) =>
        almacen.solicitudes.first.copiarCon(estado: estado);

    List<EstadoHito> estados(EstadoSolicitud e) => [
      for (final h in lineaDeTiempo(con(e))) h.estado,
    ];

    test('abierta: ofertas en curso', () {
      expect(estados(EstadoSolicitud.abierta), [
        EstadoHito.hecho,
        EstadoHito.actual,
        EstadoHito.pendiente,
        EstadoHito.pendiente,
        EstadoHito.pendiente,
        EstadoHito.pendiente,
      ]);
    });

    test('en ejecución: lo anterior hecho y lo siguiente pendiente', () {
      expect(estados(EstadoSolicitud.enEjecucion), [
        EstadoHito.hecho,
        EstadoHito.hecho,
        EstadoHito.hecho,
        EstadoHito.actual,
        EstadoHito.pendiente,
        EstadoHito.pendiente,
      ]);
    });

    test('calificada: todo hecho', () {
      expect(
        estados(EstadoSolicitud.calificada),
        everyElement(EstadoHito.hecho),
      );
    });

    test('cancelada o expirada no deja nada en curso', () {
      for (final e in [EstadoSolicitud.cancelada, EstadoSolicitud.expirada]) {
        expect(estados(e), isNot(contains(EstadoHito.actual)));
      }
    });
  });
}
