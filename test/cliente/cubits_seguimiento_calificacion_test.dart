import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/calificar/data/calificacion_demo.dart';
import 'package:agrocom_field/cliente/calificar/presentation/calificar_cubit.dart';
import 'package:agrocom_field/cliente/conformidad/data/conformidad_demo.dart';
import 'package:agrocom_field/cliente/conformidad/presentation/acta_cubit.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/problema/data/problema_demo.dart';
import 'package:agrocom_field/cliente/problema/presentation/reportar_problema_cubit.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento_repositorio.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_cubit.dart';
import 'package:agrocom_field/cliente/servicios/data/servicios_cliente_demo.dart';
import 'package:agrocom_field/cliente/servicios/presentation/historial_cubit.dart';
import 'package:agrocom_field/cliente/servicios/presentation/servicio_detalle_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/recorrido_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

/// Seguimiento que la prueba alimenta a mano.
class _SeguimientoManual implements SeguimientoRepositorio {
  var controlador = StreamController<SeguimientoVivo>();
  int suscripciones = 0;

  @override
  Stream<SeguimientoVivo> observar(String servicioId) {
    suscripciones++;
    return controlador.stream;
  }
}

void main() {
  final ahora = DateTime(2026, 11, 23, 9);
  late AlmacenDemoCliente almacen;

  setUp(() {
    almacen = AlmacenDemoCliente(datos: DatosDemo(reloj: () => ahora));
  });

  Future<void> vaciarCola() => Future<void>.delayed(Duration.zero);

  group('SeguimientoCubit', () {
    late _SeguimientoManual repo;
    late Servicio servicio;
    late RecorridoDemo recorrido;
    SeguimientoVivo cuadro(String ha) =>
        recorrido.fotograma(servicio, Decimal.parse(ha));

    setUp(() {
      repo = _SeguimientoManual();
      servicio = almacen.porId('srv-1042')!;
      recorrido = RecorridoDemo.paraLote(servicio.lote);
    });

    test('arranca cargando y pasa a en vivo con cada fotograma', () async {
      final cubit = SeguimientoCubit(repo, servicio.id);
      expect(cubit.state.fase, FaseSeguimiento.cargando);
      repo.controlador.add(cuadro('50'));
      await vaciarCola();
      expect(cubit.state.fase, FaseSeguimiento.enVivo);
      expect(cubit.state.fotograma!.hectareasCubiertas, Decimal.parse('50'));
      expect(cubit.state.terminado, isFalse);
      repo.controlador.add(cuadro('120'));
      await vaciarCola();
      expect(cubit.state.terminado, isTrue);
      await cubit.close();
    });

    test('si falla antes del primer fotograma queda en error', () async {
      final cubit = SeguimientoCubit(repo, servicio.id);
      repo.controlador.addError(const SinConexion());
      await vaciarCola();
      expect(cubit.state.fase, FaseSeguimiento.error);
      expect(cubit.state.sinConexion, isTrue);
      await cubit.close();
    });

    test('si se corta conserva el último fotograma y reintenta', () async {
      final cubit = SeguimientoCubit(repo, servicio.id);
      repo.controlador.add(cuadro('60'));
      await vaciarCola();
      repo.controlador.addError(Exception('500'));
      await vaciarCola();
      expect(cubit.state.fase, FaseSeguimiento.sinSenal);
      expect(cubit.state.sinConexion, isFalse);
      expect(cubit.state.fotograma!.hectareasCubiertas, Decimal.parse('60'));

      repo.controlador = StreamController<SeguimientoVivo>();
      cubit.reintentar();
      expect(repo.suscripciones, 2);
      // Mientras vuelve la señal sigue mostrando lo último conocido.
      expect(cubit.state.fotograma, isNotNull);
      repo.controlador.add(cuadro('70'));
      await vaciarCola();
      expect(cubit.state.fase, FaseSeguimiento.enVivo);
      expect(cubit.state.fotograma!.hectareasCubiertas, Decimal.parse('70'));
      await cubit.close();
    });
  });

  group('CalificarCubit', () {
    CalificarCubit crear() => CalificarCubit(
      CalificacionDemo(almacen, latencia: Duration.zero),
      'srv-1036',
    );

    test('sin estrella no se puede enviar', () async {
      final cubit = crear();
      expect(cubit.state.puedeEnviar, isFalse);
      await cubit.enviar();
      expect(cubit.state.fase, FaseCalificar.editando);
      expect(almacen.porId('srv-1036')!.puntajeDelCliente, isNull);
    });

    blocTest<CalificarCubit, CalificarEstado>(
      'dos toques alcanzan: estrella y enviar',
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
      verify: (_) => expect(almacen.porId('srv-1036')!.puntajeDelCliente, 5),
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
      final guardada = almacen.calificaciones['srv-1036']!;
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
        expect(cubit.state.puedeEnviar, isTrue);
        almacen.sinRed = false;
        await cubit.enviar();
        expect(cubit.state.fase, FaseCalificar.enviada);
        expect(almacen.porId('srv-1036')!.puntajeDelCliente, 3);
      },
    );
  });

  group('HistorialCubit', () {
    test('carga, filtra y resume las hectáreas en decimal exacto', () async {
      final cubit = HistorialCubit(ServiciosClienteDemo(almacen));
      expect(cubit.state.fase, FaseHistorial.cargando);
      await vaciarCola();
      expect(cubit.state.fase, FaseHistorial.listo);
      expect(cubit.state.visibles, hasLength(7));
      expect(cubit.state.totalCompletados, 3);
      // 85,5 + 64 + 210.
      expect(cubit.state.hectareasFumigadas, Decimal.parse('359.5'));

      cubit.filtrar(FiltroHistorial.activos);
      expect(
        cubit.state.visibles.map((s) => s.estado.activo),
        everyElement(isTrue),
      );
      cubit.filtrar(FiltroHistorial.completados);
      expect(cubit.state.visibles, hasLength(3));
      await cubit.close();
    });

    test('reparte las hectáreas por mes, con ceros donde no hubo', () async {
      final cubit = HistorialCubit(ServiciosClienteDemo(almacen));
      await vaciarCola();
      final meses = cubit.state.hectareasPorMes(hasta: ahora);
      expect(meses, hasLength(6));
      expect(meses.first.mes, DateTime(2026, 6));
      expect(meses.last.mes, DateTime(2026, 11));
      // Octubre: el servicio de hace 27 días (64 ha). Noviembre: 85,5 + 210.
      expect(meses[4].hectareas, Decimal.parse('64'));
      expect(meses[5].hectareas, Decimal.parse('295.5'));
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
      final cubit = HistorialCubit(ServiciosClienteDemo(almacen));
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
      final cubit = HistorialCubit(ServiciosClienteDemo(almacen));
      await vaciarCola();
      await CalificacionDemo(
        almacen,
        latencia: Duration.zero,
      ).calificarProveedor(servicioId: 'srv-1036', puntaje: 5);
      await vaciarCola();
      expect(
        cubit.state.servicios
            .firstWhere((s) => s.id == 'srv-1036')
            .puntajeDelCliente,
        5,
      );
      await cubit.close();
    });
  });

  group('ServicioDetalleCubit', () {
    ServicioDetalleCubit crear(String id) => ServicioDetalleCubit(
      servicios: ServiciosClienteDemo(almacen),
      conformidad: ConformidadDemo(almacen, latencia: Duration.zero),
      problemas: ProblemaDemo(almacen, latencia: Duration.zero),
      calificaciones: CalificacionDemo(almacen, latencia: Duration.zero),
      servicioId: id,
    );

    Future<void> asentar() async {
      for (var i = 0; i < 5; i++) {
        await vaciarCola();
      }
    }

    test('carga el servicio y después su acta y evidencias', () async {
      final cubit = crear('srv-1036');
      await asentar();
      expect(cubit.state.fase, FaseDetalle.listo);
      expect(cubit.state.servicio!.id, 'srv-1036');
      expect(cubit.state.acta!.estado, EstadoActa.pendiente);
      expect(cubit.state.expediente!.evidencias, hasLength(5));
      expect(cubit.state.problema, isNull);
      expect(
        cubit.state.hitos
            .firstWhere((h) => h.estado == EstadoHito.actual)
            .etapa,
        EtapaServicio.conformidad,
      );
      await cubit.close();
    });

    test('un id desconocido queda en no encontrado', () async {
      final cubit = crear('srv-0000');
      await asentar();
      expect(cubit.state.fase, FaseDetalle.noEncontrado);
      await cubit.close();
    });

    test('al recargar refleja la firma y el problema reportado', () async {
      final cubit = crear('srv-1036');
      await asentar();
      await ConformidadDemo(
        almacen,
        latencia: Duration.zero,
      ).firmar(servicioId: 'srv-1036', claveIdempotencia: 'c');
      await cubit.recargarAnexos();
      expect(cubit.state.acta!.estado, EstadoActa.firmada);
      expect(
        cubit.state.hitos.map((h) => h.estado),
        everyElement(EstadoHito.hecho),
      );
      await cubit.close();
    });

    test(
      'sin red al abrir queda en error; con el servicio ya cargado avisa',
      () async {
        almacen.sinRed = true;
        final cubit = crear('srv-1036');
        await asentar();
        expect(cubit.state.fase, FaseDetalle.error);
        expect(cubit.state.sinConexion, isTrue);
        almacen.sinRed = false;
        cubit.reintentar();
        await asentar();
        expect(cubit.state.fase, FaseDetalle.listo);
        expect(cubit.state.acta, isNotNull);

        almacen.sinRed = true;
        await cubit.recargarAnexos();
        expect(cubit.state.fase, FaseDetalle.listo);
        expect(cubit.state.anexosIncompletos, isTrue);
        // Conserva lo que ya había cargado.
        expect(cubit.state.acta, isNotNull);
        await cubit.close();
      },
    );
  });

  group('ActaCubit', () {
    ActaCubit crear(String id) => ActaCubit(
      ConformidadDemo(almacen, latencia: Duration.zero),
      servicioId: id,
      claveIdempotencia: 'clave-acta',
    );

    blocTest<ActaCubit, ActaEstado>(
      'carga el expediente y firma',
      build: () => crear('srv-1036'),
      act: (c) async {
        await vaciarCola();
        await c.firmar();
      },
      expect: () => [
        isA<ActaEstado>()
            .having((e) => e.fase, 'fase', FaseActa.lista)
            .having((e) => e.puedeFirmar, 'puedeFirmar', isTrue),
        isA<ActaEstado>().having((e) => e.fase, 'fase', FaseActa.firmando),
        isA<ActaEstado>()
            .having((e) => e.fase, 'fase', FaseActa.firmada)
            .having((e) => e.acta!.estado, 'acta', EstadoActa.firmada)
            .having((e) => e.evidencias.length, 'evidencias', 5),
      ],
    );

    test('un acta ya firmada no se vuelve a firmar', () async {
      final cubit = crear('srv-1039');
      await vaciarCola();
      expect(cubit.state.puedeFirmar, isFalse);
      await cubit.firmar();
      expect(cubit.state.fase, FaseActa.lista);
      await cubit.close();
    });

    test(
      'si la firma falla sin red, el expediente sigue en pantalla',
      () async {
        final cubit = crear('srv-1036');
        await vaciarCola();
        almacen.sinRed = true;
        await cubit.firmar();
        expect(cubit.state.fase, FaseActa.lista);
        expect(cubit.state.sinConexion, isTrue);
        expect(cubit.state.mensajeError, contains('Sin conexión'));
        expect(cubit.state.puedeFirmar, isTrue);
        expect(almacen.actas, isEmpty);
        almacen.sinRed = false;
        await cubit.firmar();
        expect(cubit.state.fase, FaseActa.firmada);
        await cubit.close();
      },
    );

    test('sin red al abrir queda en error y cargar lo recupera', () async {
      almacen.sinRed = true;
      final cubit = crear('srv-1036');
      await vaciarCola();
      expect(cubit.state.fase, FaseActa.error);
      almacen.sinRed = false;
      await cubit.cargar();
      expect(cubit.state.fase, FaseActa.lista);
      await cubit.close();
    });
  });

  group('ReportarProblemaCubit', () {
    ReportarProblemaCubit crear() => ReportarProblemaCubit(
      ProblemaDemo(almacen, latencia: Duration.zero),
      servicioId: 'srv-1036',
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

    test('envía y devuelve el caso', () async {
      final cubit = crear()
        ..elegirMotivo(MotivoProblema.coberturaIncompleta)
        ..cambiarDetalle('  Faltó el borde norte del lote.  ');
      await cubit.enviar();
      expect(cubit.state.fase, FaseReporte.enviado);
      expect(cubit.state.caso!.numeroCaso, 'C-2041');
      expect(cubit.state.caso!.detalle, 'Faltó el borde norte del lote.');
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
        expect(cubit.state.motivo, MotivoProblema.danoCultivos);
        almacen.sinRed = false;
        await cubit.enviar();
        await cubit.enviar();
        expect(cubit.state.fase, FaseReporte.enviado);
        expect(almacen.problemas, hasLength(1));
      },
    );
  });
}
