import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/calificar/data/calificacion_demo.dart';
import 'package:agrocom_field/cliente/conformidad/data/conformidad_demo.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/problema/data/problema_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/servicios/data/servicios_cliente_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

void main() {
  final ahora = DateTime(2026, 11, 23, 9);
  late AlmacenDemoCliente almacen;
  late ConformidadDemo conformidad;
  late ProblemaDemo problemas;
  late CalificacionDemo calificaciones;

  setUp(() {
    almacen = AlmacenDemoCliente(datos: DatosDemo(reloj: () => ahora));
    conformidad = ConformidadDemo(almacen, latencia: Duration.zero);
    problemas = ProblemaDemo(almacen, latencia: Duration.zero);
    calificaciones = CalificacionDemo(almacen, latencia: Duration.zero);
  });

  group('conformidad', () {
    test('el completado sin calificar espera la firma del cliente', () async {
      final e = await conformidad.expediente('srv-1036');
      expect(e.acta!.estado, EstadoActa.pendiente);
      expect(e.acta!.hectareasConfirmadas, Decimal.parse('210.0'));
      // 1,2 L/ha por 210 ha, en decimal exacto.
      expect(e.acta!.litrosAplicados, Decimal.parse('252.00'));
      expect(e.acta!.venceConformidad.isAfter(ahora), isTrue);
      expect(e.evidencias.map((x) => x.tipo), TipoEvidencia.values);
    });

    test(
      'el servicio en ejecución tiene evidencias y todavía no acta',
      () async {
        final e = await conformidad.expediente('srv-1042');
        expect(e.acta, isNull);
        expect(e.evidencias, hasLength(3));
      },
    );

    test('un servicio sin empezar no tiene expediente', () async {
      final e = await conformidad.expediente('srv-1047');
      expect(e.acta, isNull);
      expect(e.evidencias, isEmpty);
    });

    test('firmar dos veces devuelve la misma acta firmada', () async {
      final a = await conformidad.firmar(
        servicioId: 'srv-1036',
        claveIdempotencia: 'clave-1',
      );
      final b = await conformidad.firmar(
        servicioId: 'srv-1036',
        claveIdempotencia: 'clave-1',
      );
      expect(a.estado, EstadoActa.firmada);
      expect(a.firmadaEn, ahora);
      expect(b.firmadaEn, a.firmadaEn);
      final e = await conformidad.expediente('srv-1036');
      expect(e.acta!.estado, EstadoActa.firmada);
    });

    test('no se firma un servicio que no terminó', () {
      expect(
        conformidad.firmar(servicioId: 'srv-1042', claveIdempotencia: 'c'),
        throwsA(isA<OperacionRechazada>()),
      );
    });

    test(
      'con un problema reportado el acta queda observada y no se firma',
      () async {
        await problemas.reportar(
          const ReporteProblema(
            servicioId: 'srv-1036',
            motivo: MotivoProblema.coberturaIncompleta,
            detalle: 'Faltó la franja del borde norte.',
            claveIdempotencia: 'p-1',
          ),
        );
        final e = await conformidad.expediente('srv-1036');
        expect(e.acta!.estado, EstadoActa.observada);
        expect(
          conformidad.firmar(servicioId: 'srv-1036', claveIdempotencia: 'c'),
          throwsA(isA<OperacionRechazada>()),
        );
      },
    );
  });

  group('problemas', () {
    const reporte = ReporteProblema(
      servicioId: 'srv-1036',
      motivo: MotivoProblema.malaAplicacion,
      detalle: 'Doble pasada en la cabecera sur.',
      claveIdempotencia: 'p-1',
    );

    test('un servicio sin reporte no tiene problema', () async {
      expect(await problemas.delServicio('srv-1036'), isNull);
    });

    test('reintentar el envío no abre un segundo caso', () async {
      final a = await problemas.reportar(reporte);
      final b = await problemas.reportar(reporte);
      expect(b.numeroCaso, a.numeroCaso);
      expect(almacen.problemas, hasLength(1));
      expect(a.motivo, MotivoProblema.malaAplicacion);
      expect(a.abiertoEn, ahora);
      expect(
        (await problemas.delServicio('srv-1036'))!.numeroCaso,
        a.numeroCaso,
      );
    });

    test('hay un solo problema por servicio aunque cambie la clave', () async {
      final a = await problemas.reportar(reporte);
      final b = await problemas.reportar(
        const ReporteProblema(
          servicioId: 'srv-1036',
          motivo: MotivoProblema.cobroIndebido,
          detalle: 'El monto no coincide.',
          claveIdempotencia: 'p-2',
        ),
      );
      expect(b.numeroCaso, a.numeroCaso);
      expect(b.motivo, MotivoProblema.malaAplicacion);
    });
  });

  group('calificación', () {
    test('guarda estrellas, etiquetas y comentario una sola vez', () async {
      await calificaciones.calificarProveedor(
        servicioId: 'srv-1036',
        puntaje: 4,
        etiquetas: {
          EtiquetaCalificacion.puntualidad,
          EtiquetaCalificacion.comunicacion,
        },
        comentario: 'Llegaron a horario.',
      );
      await calificaciones.calificarProveedor(
        servicioId: 'srv-1036',
        puntaje: 1,
      );
      final c = (await calificaciones.emitida('srv-1036'))!;
      expect(c.puntaje, 4);
      expect(c.etiquetas, {
        EtiquetaCalificacion.puntualidad,
        EtiquetaCalificacion.comunicacion,
      });
      expect(c.comentario, 'Llegaron a horario.');
      expect(almacen.porId('srv-1036')!.puntajeDelCliente, 4);
    });

    test('un servicio sin calificar no tiene calificación emitida', () async {
      expect(await calificaciones.emitida('srv-1036'), isNull);
      expect((await calificaciones.emitida('srv-1039'))!.puntaje, 5);
    });
  });

  group('sin red', () {
    setUp(() => almacen.sinRed = true);

    test('los repositorios lanzan SinConexion y no escriben nada', () async {
      await expectLater(
        conformidad.expediente('srv-1036'),
        throwsA(isA<SinConexion>()),
      );
      await expectLater(
        conformidad.firmar(servicioId: 'srv-1036', claveIdempotencia: 'c'),
        throwsA(isA<SinConexion>()),
      );
      await expectLater(
        calificaciones.calificarProveedor(servicioId: 'srv-1036', puntaje: 5),
        throwsA(isA<SinConexion>()),
      );
      await expectLater(
        problemas.reportar(
          const ReporteProblema(
            servicioId: 'srv-1036',
            motivo: MotivoProblema.equipoAusente,
            detalle: 'Nadie llegó al lote.',
            claveIdempotencia: 'p',
          ),
        ),
        throwsA(isA<SinConexion>()),
      );
      await expectLater(
        ServiciosClienteDemo(almacen).observar().first,
        throwsA(isA<SinConexion>()),
      );
      await expectLater(
        SeguimientoDemo(almacen).observar('srv-1042').first,
        throwsA(isA<SinConexion>()),
      );
      expect(almacen.actas, isEmpty);
      expect(almacen.problemas, isEmpty);
      expect(almacen.porId('srv-1036')!.puntajeDelCliente, isNull);
    });
  });

  test('el tiempo restante del seguimiento baja hasta cero', () async {
    final cuadros = await SeguimientoDemo(
      almacen,
      intervalo: Duration.zero,
      pasoHectareas: '20',
    ).observar('srv-1042').toList();
    final etas = [for (final c in cuadros) c.etaMinutos!];
    expect(etas.first, 74);
    expect(etas.last, 0);
    expect(etas, orderedEquals([...etas]..sort((a, b) => b.compareTo(a))));
  });
}
