import 'package:agrocom_field/cliente/calificar/data/calificacion_red.dart';
import 'package:agrocom_field/cliente/conformidad/data/conformidad_red.dart';
import 'package:agrocom_field/cliente/cuenta/data/cuenta_red.dart';
import 'package:agrocom_field/cliente/inicio/data/inicio_cliente_red.dart';
import 'package:agrocom_field/cliente/inicio/domain/inicio_cliente_repositorio.dart';
import 'package:agrocom_field/cliente/problema/data/problema_red.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_red.dart';
import 'package:agrocom_field/cliente/servicios/data/servicios_cliente_red.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_red.dart';

const _ficha = {
  'cliente': {
    'id': 1,
    'tipo': 'empresa',
    'razon_social': 'Agropecuaria San Rafael SRL',
    'telefono': '+591 76543210',
    'estado': 'activo',
    'calificacion_promedio': '4.00',
    'calificaciones_conteo': 1,
  },
};

const _sesion = {
  'usuario': {
    'id': 20,
    'name': 'Rosario Antelo Vaca',
    'username': 'agro.sanrafael',
    'persona_id': null,
  },
};

EntornoRed _entornoConServicios() {
  final red = EntornoRed();
  red.servidor
    ..responder('GET', '/api/zonas', cuerpo: zonasJson)
    ..responder(
      'GET',
      '/api/solicitudes',
      cuerpo: {
        'solicitudes': [
          solicitudJson(id: 9, estado: 'borrador', proveedorId: null),
          solicitudJson(id: 8),
          solicitudJson(id: 5, estado: 'asignada', montoFinal: null),
        ],
        'pagina': 1,
        'paginas': 1,
        'total': 3,
      },
    )
    ..responder(
      'GET',
      '/api/solicitudes/8/calificaciones',
      cuerpo: calificacionesJson(
        calificacion: {
          'id': 3,
          'estrellas': 4,
          'etiquetas': ['puntualidad', 'comunicacion'],
          'comentario': 'Bien',
          'creada_en': '2026-11-25T10:00:00+00:00',
        },
      ),
    );
  return red;
}

void main() {
  group('ServiciosClienteRed', () {
    test('lista los servicios sin borradores y con su calificación', () async {
      final red = _entornoConServicios();
      final repo = ServiciosClienteRed(red.fuente);
      final servicios = await repo.observar().first;
      expect(servicios.map((s) => s.id), ['8', '5']);
      final completado = servicios.first;
      expect(completado.puntajeDelCliente, 4);
      expect(completado.proveedor?.nombre, 'Agrocom SRL');
      expect(completado.lote.zona, 'Cuatro Cañadas');
      expect(servicios.last.estado, EstadoServicio.asignado);
    });

    test('recorre todas las páginas', () async {
      final red = EntornoRed();
      red.servidor
        ..responder('GET', '/api/zonas', cuerpo: zonasJson)
        ..responder(
          'GET',
          '/api/solicitudes',
          cuerpo: {
            'solicitudes': [solicitudJson(id: 1, estado: 'asignada')],
            'pagina': 1,
            'paginas': 2,
            'total': 2,
          },
        );
      final servicios = await red.fuente.cargar();
      expect(servicios, hasLength(2));
      expect(
        red.servidor.de('GET', '/api/solicitudes').map((p) => p.query['page']),
        [1, 2],
      );
    });

    test('sin red muestra lo último conocido; sin nada, falla', () async {
      final red = _entornoConServicios();
      final repo = ServiciosClienteRed(red.fuente);
      red.servidor.sinRed = true;
      await expectLater(repo.observar().first, throwsA(isA<SinConexion>()));
      red.servidor.sinRed = false;
      await repo.observar().first;
      red.servidor.sinRed = true;
      expect((await repo.observar().first).map((s) => s.id), ['8', '5']);
    });

    test('porId devuelve el servicio o null si no es del cliente', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/8',
        cuerpo: {'solicitud': solicitudJson(id: 8)},
      );
      final repo = ServiciosClienteRed(red.fuente);
      expect((await repo.porId('8'))?.precio, Decimal.parse('7200.00'));
      expect(await repo.porId('77'), isNull);
    });

    test('cerrar sesión descarta lo guardado', () async {
      final red = _entornoConServicios();
      await red.fuente.cargar();
      red.fuente.olvidar();
      red.servidor.sinRed = true;
      await expectLater(
        red.fuente.observar().first,
        throwsA(isA<SinConexion>()),
      );
    });
  });

  group('InicioClienteRed', () {
    test('arma el resumen con el nombre, los servicios y los avisos', () async {
      final red = _entornoConServicios();
      red.servidor
        ..responder('GET', '/api/auth/sesion', cuerpo: _sesion)
        ..responder('GET', '/api/clientes/mi', cuerpo: _ficha)
        ..responder(
          'GET',
          '/api/notificaciones',
          cuerpo: {
            'data': [
              {
                'id': 51,
                'tipo': 'disputa_resuelta',
                'titulo': 'La disputa del servicio #8 se cerró.',
                'recurso_tipo': 'disputa',
                'recurso_id': 2,
                'leida': false,
                'creada_en': '2026-11-24T12:18:30+00:00',
              },
              {
                'id': 48,
                'tipo': 'solicitud_completada',
                'titulo': 'Ya leído',
                'recurso_tipo': 'solicitud',
                'recurso_id': 8,
                'leida': true,
                'creada_en': '2026-11-24T12:18:30+00:00',
              },
            ],
            'no_leidas': 1,
          },
        );
      final repo = InicioClienteRed(red.fuente, red.http, CuentaRed(red.http));
      final resumen = await repo.observar().first;
      expect(resumen.nombre, 'Rosario');
      expect(resumen.empresa, 'Agropecuaria San Rafael SRL');
      expect(resumen.servicioActivo?.id, '5');
      expect(resumen.recientes.map((s) => s.id), ['8']);
      expect(resumen.avisos, hasLength(1));
      expect(resumen.avisos.single.tono, TonoAvisoInicio.alerta);
    });

    test('sin red emite InicioSinConexion', () async {
      final red = EntornoRed();
      red.servidor.sinRed = true;
      final repo = InicioClienteRed(red.fuente, red.http, CuentaRed(red.http));
      await expectLater(
        repo.observar().first,
        throwsA(isA<InicioSinConexion>()),
      );
    });

    test('sin avisos del servidor el inicio sigue funcionando', () async {
      final red = _entornoConServicios();
      red.servidor
        ..responder('GET', '/api/auth/sesion', cuerpo: _sesion)
        ..responder('GET', '/api/clientes/mi', cuerpo: _ficha)
        ..responder('GET', '/api/notificaciones', codigo: 500, cuerpo: {});
      final repo = InicioClienteRed(red.fuente, red.http, CuentaRed(red.http));
      expect((await repo.observar().first).avisos, isEmpty);
    });
  });

  group('CuentaRed', () {
    test('junta usuario, ficha y total de servicios', () async {
      final red = _entornoConServicios();
      red.servidor
        ..responder('GET', '/api/auth/sesion', cuerpo: _sesion)
        ..responder('GET', '/api/clientes/mi', cuerpo: _ficha);
      final cuenta = await CuentaRed(red.http).cuenta();
      expect(cuenta.nombre, 'Rosario Antelo Vaca');
      expect(cuenta.usuario, 'agro.sanrafael');
      expect(cuenta.empresa, 'Agropecuaria San Rafael SRL');
      expect(cuenta.telefono, '+591 76543210');
      expect(cuenta.serviciosTotales, 3);
    });

    test('una persona no tiene empresa', () async {
      final red = _entornoConServicios();
      red.servidor
        ..responder('GET', '/api/auth/sesion', cuerpo: _sesion)
        ..responder(
          'GET',
          '/api/clientes/mi',
          cuerpo: {
            'cliente': {..._ficha['cliente']!, 'tipo': 'persona'},
          },
        );
      expect((await CuentaRed(red.http).cuenta()).empresa, isEmpty);
    });
  });

  group('CalificacionRed', () {
    test('califica al proveedor con una clave estable por servicio', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/calificaciones',
        codigo: 201,
        cuerpo: {'calificaciones': []},
      );
      final repo = CalificacionRed(red.http, red.fuente);
      await repo.calificarProveedor(
        servicioId: '8',
        puntaje: 5,
        etiquetas: {
          EtiquetaCalificacion.coberturaPareja,
          EtiquetaCalificacion.ordenEnElLote,
        },
        comentario: ' Muy bien ',
      );
      await repo.calificarProveedor(servicioId: '8', puntaje: 5);
      final envios = red.servidor
          .de('POST', '/api/solicitudes/8/calificaciones')
          .toList();
      final primero = (envios.first.cuerpo! as Map)['calificaciones'][0] as Map;
      final segundo = (envios.last.cuerpo! as Map)['calificaciones'][0] as Map;
      expect(primero['sujeto_tipo'], 'proveedor');
      expect(primero['estrellas'], 5);
      expect(primero['etiquetas'], ['cobertura_pareja', 'orden_lote']);
      expect(primero['comentario'], 'Muy bien');
      expect(segundo.containsKey('comentario'), isFalse);
      expect(primero['uuid_cliente'], segundo['uuid_cliente']);
    });

    test('un 409 (ya calificado) no es un error', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/calificaciones',
        codigo: 409,
        cuerpo: {},
      );
      await CalificacionRed(
        red.http,
        red.fuente,
      ).calificarProveedor(servicioId: '8', puntaje: 4);
    });

    test('sin red falla con SinConexion', () async {
      final red = _entornoConServicios();
      red.servidor.sinRed = true;
      await expectLater(
        CalificacionRed(
          red.http,
          red.fuente,
        ).calificarProveedor(servicioId: '8', puntaje: 4),
        throwsA(isA<SinConexion>()),
      );
    });

    test('lee lo emitido y lo recibido', () async {
      final red = _entornoConServicios();
      red.servidor.responder('GET', '/api/clientes/mi', cuerpo: _ficha);
      final repo = CalificacionRed(red.http, red.fuente);
      final emitida = await repo.emitida('8');
      expect(emitida?.puntaje, 4);
      expect(emitida?.etiquetas, {
        EtiquetaCalificacion.puntualidad,
        EtiquetaCalificacion.comunicacion,
      });
      expect(emitida?.comentario, 'Bien');
      final recibidas = await repo.recibidas();
      expect(recibidas.promedio, 4.0);
      expect(recibidas.total, 1);
    });

    test('sin calificación dada, emitida es null', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/8/calificaciones',
        cuerpo: calificacionesJson(),
      );
      expect(await CalificacionRed(red.http, red.fuente).emitida('8'), isNull);
    });
  });

  group('ProblemaRed', () {
    final disputa = {
      'id': 9,
      'solicitud_id': 7,
      'abierta_por': 'cliente',
      'motivo': 'cobertura_incompleta',
      'detalle': 'Faltan franjas',
      'monto_en_disputa': '7200.00',
      'estado': 'en_revision',
      'ronda': 1,
      'creada_en': '2026-11-24T12:18:29+00:00',
    };

    test('abre la disputa con el motivo del contrato', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/7/disputas',
        codigo: 201,
        cuerpo: {'disputa': disputa},
      );
      final caso = await ProblemaRed(red.http, red.fuente).reportar(
        const ReporteProblema(
          servicioId: '7',
          motivo: MotivoProblema.danoCultivos,
          detalle: ' Faltan franjas ',
          claveIdempotencia: 'k',
        ),
      );
      final cuerpo =
          red.servidor.de('POST', '/api/solicitudes/7/disputas').single.cuerpo!
              as Map;
      expect(cuerpo['motivo'], 'dano_a_cultivos_o_terceros');
      expect(cuerpo['detalle'], 'Faltan franjas');
      expect(caso.numeroCaso, 'D-9');
      expect(caso.estado, EstadoProblema.enRevision);
      expect(caso.motivo, MotivoProblema.coberturaIncompleta);
    });

    test('si ya había una disputa (409) devuelve esa', () async {
      final red = _entornoConServicios();
      red.servidor
        ..responder(
          'POST',
          '/api/solicitudes/7/disputas',
          codigo: 409,
          cuerpo: {},
        )
        ..responder(
          'GET',
          '/api/solicitudes/7/disputa',
          cuerpo: {'disputa': disputa},
        );
      final caso = await ProblemaRed(red.http, red.fuente).reportar(
        const ReporteProblema(
          servicioId: '7',
          motivo: MotivoProblema.malaAplicacion,
          detalle: 'x',
          claveIdempotencia: 'k',
        ),
      );
      expect(caso.numeroCaso, 'D-9');
    });

    test('delServicio devuelve null sin disputa y un 422 se explica', () async {
      final red = _entornoConServicios();
      final repo = ProblemaRed(red.http, red.fuente);
      expect(await repo.delServicio('7'), isNull);
      red.servidor.responder(
        'POST',
        '/api/solicitudes/7/disputas',
        codigo: 422,
        cuerpo: {'message': 'El plazo para abrir la disputa venció.'},
      );
      await expectLater(
        repo.reportar(
          const ReporteProblema(
            servicioId: '7',
            motivo: MotivoProblema.malaAplicacion,
            detalle: 'x',
            claveIdempotencia: 'k',
          ),
        ),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('venció'),
          ),
        ),
      );
    });
  });

  group('ConformidadRed', () {
    final historial = [
      pasoHistorial('borrador', '2026-11-24T12:00:00+00:00'),
      pasoHistorial('en_ejecucion', '2026-11-27T10:00:00+00:00'),
      pasoHistorial('ejecutada', '2026-11-27T13:25:00+00:00'),
    ];

    test('un servicio ejecutado espera la firma del cliente', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/6',
        cuerpo: {
          'solicitud': solicitudJson(
            id: 6,
            estado: 'ejecutada',
            montoFinal: null,
            historial: historial,
          ),
        },
      );
      final expediente = await ConformidadRed(
        red.http,
        red.fuente,
      ).expediente('6');
      final acta = expediente.acta!;
      expect(acta.estado, EstadoActa.pendiente);
      expect(acta.hectareasConfirmadas, Decimal.parse('60'));
      expect(acta.litrosAplicados, Decimal.parse('120'));
      expect(
        acta.fin.difference(acta.inicio),
        const Duration(hours: 3, minutes: 25),
      );
      expect(
        acta.venceConformidad.difference(acta.fin),
        const Duration(hours: 72),
      );
      expect(expediente.evidencias, isEmpty);
    });

    test('las hectáreas confirmadas salen del monto final facturado', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/6',
        cuerpo: {
          'solicitud': solicitudJson(
            id: 6,
            montoFinal: '6000.00',
            historial: [
              ...historial,
              pasoHistorial('completada', '2026-11-28T09:00:00+00:00'),
            ],
          ),
        },
      );
      final acta = (await ConformidadRed(
        red.http,
        red.fuente,
      ).expediente('6')).acta!;
      expect(acta.estado, EstadoActa.firmada);
      expect(acta.hectareasConfirmadas, Decimal.parse('50'));
      expect(acta.firmadaEn, isNotNull);
    });

    test('un servicio en disputa queda con el acta observada', () {
      expect(
        ConformidadRed.actaDe(solicitudJson(estado: 'en_disputa'))?.estado,
        EstadoActa.observada,
      );
      expect(ConformidadRed.actaDe(solicitudJson(estado: 'asignada')), isNull);
    });

    test(
      'firmar usa el endpoint de conformidad y devuelve el acta firmada',
      () async {
        final red = _entornoConServicios();
        red.servidor.responder(
          'POST',
          '/api/solicitudes/6/conformidad',
          cuerpo: {
            'solicitud': solicitudJson(
              id: 6,
              historial: [
                ...historial,
                pasoHistorial('completada', '2026-11-28T09:00:00+00:00'),
              ],
            ),
          },
        );
        final acta = await ConformidadRed(
          red.http,
          red.fuente,
        ).firmar(servicioId: '6', claveIdempotencia: 'k');
        expect(acta.estado, EstadoActa.firmada);
        expect(
          red.servidor.de('POST', '/api/solicitudes/6/conformidad'),
          hasLength(1),
        );
      },
    );

    test('firmar antes de tiempo muestra el motivo del servidor', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/6/conformidad',
        codigo: 422,
        cuerpo: {'message': 'La solicitud todavía no está ejecutada.'},
      );
      await expectLater(
        ConformidadRed(
          red.http,
          red.fuente,
        ).firmar(servicioId: '6', claveIdempotencia: 'k'),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('ejecutada'),
          ),
        ),
      );
    });
  });

  group('SeguimientoRed', () {
    test('emite el estado real y termina cuando el servicio cierra', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/5',
        secuencia: [
          {
            'solicitud': solicitudJson(
              id: 5,
              estado: 'en_ejecucion',
              montoFinal: null,
            ),
          },
          {'solicitud': solicitudJson(id: 5, estado: 'ejecutada')},
        ],
        cuerpo: null,
      );
      final repo = SeguimientoRed(red.fuente, intervalo: Duration.zero);
      final cuadros = await repo.observar('5').toList();
      expect(cuadros.map((c) => c.estado), [
        EstadoServicio.enEjecucion,
        EstadoServicio.completado,
      ]);
      expect(cuadros.first.hectareasDeclaradas, Decimal.parse('60'));
      expect(cuadros.first.trazado, isEmpty);
    });

    test('sin red el error llega al flujo', () async {
      final red = EntornoRed();
      red.servidor.sinRed = true;
      await expectLater(
        SeguimientoRed(red.fuente).observar('5').first,
        throwsA(isA<SinConexion>()),
      );
    });
  });
}
