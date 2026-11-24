import 'package:agrocom_field/cliente/calificar/data/calificacion_red.dart';
import 'package:agrocom_field/cliente/cuenta/data/cuenta_red.dart';
import 'package:agrocom_field/cliente/inicio/data/inicio_cliente_red.dart';
import 'package:agrocom_field/cliente/inicio/domain/inicio_cliente_repositorio.dart';
import 'package:agrocom_field/cliente/problema/data/problema_red.dart';
import 'package:agrocom_field/cliente/ofertas/data/ofertas_red.dart';
import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_red.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento.dart';
import 'package:agrocom_field/cliente/solicitudes/data/solicitudes_red.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
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
          solicitudJson(
            id: 9,
            estado: 'borrador',
            proveedorId: null,
            ofertaAdjudicadaId: null,
          ),
          solicitudJson(id: 8),
          solicitudJson(
            id: 5,
            estado: 'con_ofertas',
            proveedorId: null,
            ofertaAdjudicadaId: null,
            precioAcordado: null,
            montoFinal: null,
            ejecutadas: null,
            porcentaje: '0.00',
          ),
        ],
        'pagina': 1,
        'paginas': 1,
        'total': 3,
      },
    )
    ..responder(
      'GET',
      '/api/solicitudes/5/ofertas',
      cuerpo: {
        'ofertas': [
          ofertaJson(id: 21, solicitudId: 5, precioHa: '130.0000'),
          ofertaJson(id: 22, solicitudId: 5, precioHa: '118.0000'),
          ofertaJson(id: 23, solicitudId: 5, estado: 'vencida'),
        ],
      },
    )
    ..responder(
      'GET',
      '/api/ofertas/14',
      cuerpo: {
        'oferta': ofertaJson(id: 14, solicitudId: 8, estado: 'aceptada'),
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
  group('SolicitudesRed', () {
    test(
      'lista las solicitudes sin borradores, con piloto y calificación',
      () async {
        final red = _entornoConServicios();
        final repo = SolicitudesRed(red.http, red.fuente);
        final solicitudes = await repo.observar().first;
        expect(solicitudes.map((s) => s.id), ['8', '5']);
        final calificada = solicitudes.first;
        expect(calificada.estado, EstadoSolicitud.calificada);
        expect(calificada.puntajeDelCliente, 4);
        expect(calificada.nombreProveedor, 'Mamani Agroservicios');
        expect(calificada.lote.zona, 'Cuatro Cañadas');
        final conOfertas = solicitudes.last;
        expect(conOfertas.estado, EstadoSolicitud.conOfertas);
        // Cuenta solo las ofertas vigentes: la vencida no suma.
        expect(conOfertas.ofertasVigentes, 2);
      },
    );

    test('recorre todas las páginas', () async {
      final red = EntornoRed();
      red.servidor
        ..responder('GET', '/api/zonas', cuerpo: zonasJson)
        ..responder(
          'GET',
          '/api/solicitudes',
          cuerpo: {
            'solicitudes': [
              solicitudJson(
                id: 1,
                estado: 'adjudicada',
                ofertaAdjudicadaId: null,
              ),
            ],
            'pagina': 1,
            'paginas': 2,
            'total': 2,
          },
        );
      final solicitudes = await red.fuente.cargar();
      expect(solicitudes, hasLength(2));
      expect(
        red.servidor.de('GET', '/api/solicitudes').map((p) => p.query['page']),
        [1, 2],
      );
    });

    test('sin red muestra lo último conocido; sin nada, falla', () async {
      final red = _entornoConServicios();
      final repo = SolicitudesRed(red.http, red.fuente);
      red.servidor.sinRed = true;
      await expectLater(repo.observar().first, throwsA(isA<SinConexion>()));
      red.servidor.sinRed = false;
      await repo.observar().first;
      red.servidor.sinRed = true;
      expect((await repo.observar().first).map((s) => s.id), ['8', '5']);
    });

    test('porId devuelve la solicitud o null si no es del cliente', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/8',
        cuerpo: {'solicitud': solicitudJson(id: 8)},
      );
      final repo = SolicitudesRed(red.http, red.fuente);
      expect((await repo.porId('8'))?.montoFinal, Decimal.parse('7440.00'));
      expect(await repo.porId('77'), isNull);
    });

    test(
      'cambiar el precio manda el decimal como texto y vuelve a leer',
      () async {
        final red = _entornoConServicios();
        red.servidor.responder(
          'POST',
          '/api/solicitudes/5/precio',
          cuerpo: {'solicitud': solicitudJson(id: 5, estado: 'abierta')},
        );
        final repo = SolicitudesRed(red.http, red.fuente);
        await repo.observar().first;
        final antes = red.servidor.de('GET', '/api/solicitudes').length;
        await repo.cambiarPrecio('5', Decimal.parse('118.50'));
        final envio = red.servidor
            .de('POST', '/api/solicitudes/5/precio')
            .single;
        expect((envio.cuerpo! as Map)['precio_ha_propuesto'], '118.5');
        expect(red.servidor.de('GET', '/api/solicitudes').length, antes + 1);
      },
    );

    test('cancelar manda el motivo; un 422 se explica', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/5/cancelar',
        cuerpo: {'solicitud': solicitudJson(id: 5, estado: 'cancelada')},
      );
      final repo = SolicitudesRed(red.http, red.fuente);
      await repo.cancelar('5', ' Cambió la fecha ');
      expect(
        (red.servidor.de('POST', '/api/solicitudes/5/cancelar').single.cuerpo!
            as Map)['motivo'],
        'Cambió la fecha',
      );
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/cancelar',
        codigo: 422,
        cuerpo: {'message': 'La solicitud ya no admite cancelación.'},
      );
      await expectLater(
        repo.cancelar('8', 'x'),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('cancelación'),
          ),
        ),
      );
    });

    test('renovar vuelve a abrir la solicitud expirada', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/5/renovar',
        cuerpo: {'solicitud': solicitudJson(id: 5, estado: 'abierta')},
      );
      await SolicitudesRed(red.http, red.fuente).renovar('5');
      expect(
        red.servidor.de('POST', '/api/solicitudes/5/renovar'),
        hasLength(1),
      );
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

  group('OfertasRed', () {
    test('lista primero las vigentes, de menor a mayor precio', () async {
      final red = _entornoConServicios();
      final ofertas = await OfertasRed(red.http, red.fuente).deLaSolicitud('5');
      expect(ofertas.map((o) => o.id), ['22', '21', '23']);
      expect(ofertas.first.precioHa, Decimal.parse('118'));
      expect(ofertas.last.estado, EstadoOferta.vencida);
    });

    test('aceptar adjudica y vuelve a leer las solicitudes', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/ofertas/22/aceptar',
        cuerpo: {'oferta': ofertaJson(id: 22, estado: 'aceptada')},
      );
      final repo = OfertasRed(red.http, red.fuente);
      await repo.aceptar('22');
      expect(red.servidor.de('POST', '/api/ofertas/22/aceptar'), hasLength(1));
      expect(red.servidor.de('GET', '/api/solicitudes'), isNotEmpty);
    });

    test('contraofertar manda el precio y la clave de idempotencia', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/ofertas/21/contraofertar',
        codigo: 201,
        cuerpo: {'oferta': ofertaJson(id: 30, numero: 2, autor: 'cliente')},
      );
      await OfertasRed(red.http, red.fuente).contraofertar(
        '21',
        precioHa: Decimal.parse('122.50'),
        claveIdempotencia: 'clave-1',
        nota: ' Mi mejor precio ',
      );
      final cuerpo =
          red.servidor
                  .de('POST', '/api/ofertas/21/contraofertar')
                  .single
                  .cuerpo!
              as Map;
      expect(cuerpo['precio_ha'], '122.5');
      expect(cuerpo['uuid_cliente'], 'clave-1');
      expect(cuerpo['nota'], 'Mi mejor precio');
    });

    test('rechazar cierra esa negociación', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/ofertas/21/rechazar',
        cuerpo: {'oferta': ofertaJson(id: 21, estado: 'rechazada')},
      );
      await OfertasRed(red.http, red.fuente).rechazar('21');
      expect(red.servidor.de('POST', '/api/ofertas/21/rechazar'), hasLength(1));
    });

    test('una oferta que ya no está vigente llega como OfertaCambio', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/ofertas/21/aceptar',
        codigo: 409,
        cuerpo: {
          'message': 'La oferta ya no está vigente: venció o la retiraron.',
          'codigo': 'oferta_no_vigente',
        },
      );
      await expectLater(
        OfertasRed(red.http, red.fuente).aceptar('21'),
        throwsA(
          isA<OfertaCambio>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('ya no está vigente'),
          ),
        ),
      );
    });

    test('si otra oferta ya se adjudicó, también es OfertaCambio', () async {
      final red = _entornoConServicios();
      red.servidor.responder(
        'POST',
        '/api/ofertas/21/aceptar',
        codigo: 409,
        cuerpo: {
          'message': 'La solicitud ya se adjudicó.',
          'codigo': 'solicitud_ya_adjudicada',
        },
      );
      await expectLater(
        OfertasRed(red.http, red.fuente).aceptar('21'),
        throwsA(isA<OfertaCambio>()),
      );
    });

    test('sin red falla con SinConexion', () async {
      final red = _entornoConServicios();
      red.servidor.sinRed = true;
      await expectLater(
        OfertasRed(red.http, red.fuente).aceptar('21'),
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
      expect(resumen.solicitudActiva?.id, '5');
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

  group('SeguimientoRed', () {
    const avance = {
      'avance': {
        'solicitud_id': 5,
        'estado': 'en_ejecucion',
        'lado': 'cliente',
        'hectareas_solicitadas': '80.0000',
        'hectareas_ejecutadas': '51.2000',
        'porcentaje_avance': '64.00',
        'precio_ha_acordado': '115.0000',
        'monto_estimado': '9200.00',
        'monto_final': null,
        'iniciada_en': '2026-11-24T11:03:45+00:00',
        'ultimo_avance_en': '2026-11-24T14:03:45+00:00',
        'cierre_solicitado_en': null,
        'finalizada_en': null,
        'registros': [
          {
            'id': 3,
            'uuid_cliente': 'u3',
            'tipo': 'avance',
            'hectareas_ejecutadas': '51.2000',
            'porcentaje': '64.00',
            'nota': 'Terminamos el sector central.',
            'registrado_en': '2026-11-24T14:03:45+00:00',
          },
        ],
        'fotos': [
          {
            'id': 2,
            'uuid_cliente': 'f2',
            'tipo': 'foto_avance',
            'avance_id': 3,
            'url': '/api/evidencias/2/archivo',
            'subida_en': '2026-11-24T14:03:45+00:00',
          },
        ],
      },
    };

    test(
      'el avance trae las hectáreas exactas, las notas y las fotos',
      () async {
        final red = EntornoRed();
        red.servidor.responder(
          'GET',
          '/api/solicitudes/5/avance',
          cuerpo: avance,
        );
        final a = await SeguimientoRed(red.http).avance('5');
        expect(a.hectareasEjecutadas, Decimal.parse('51.2'));
        expect(a.porcentaje, Decimal.parse('64'));
        expect(a.progreso, closeTo(0.64, 1e-9));
        expect(a.registros.single.nota, 'Terminamos el sector central.');
        expect(a.fotos.single.ruta, '/api/evidencias/2/archivo');
        // La foto lleva la nota del avance al que pertenece.
        expect(a.fotos.single.nota, 'Terminamos el sector central.');
      },
    );

    test('la ubicación del piloto es un punto con su antigüedad', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/5/ubicacion-piloto',
        cuerpo: {
          'ubicacion': {
            'latitud': -17.512,
            'longitud': -63.17,
            'precision_m': 12,
            'capturado_en': '2026-11-24T16:01:45+00:00',
            'antiguedad_s': 90,
            'vigente': true,
          },
        },
      );
      final u = await SeguimientoRed(red.http).ubicacionDelPiloto('5');
      expect(u?.punto, const GeoPunto(-17.512, -63.17));
      expect(u?.vigente, isTrue);
      expect(u?.precisionMetros, 12);
    });

    test('sin ubicación el servidor responde null', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/5/ubicacion-piloto',
        cuerpo: {'ubicacion': null},
      );
      expect(await SeguimientoRed(red.http).ubicacionDelPiloto('5'), isNull);
    });

    test(
      'los mensajes se piden con el cursor y marcan quién escribió',
      () async {
        final red = EntornoRed();
        red.servidor.responder(
          'GET',
          '/api/solicitudes/5/mensajes',
          cuerpo: {
            'mensajes': [
              {
                'id': 7,
                'uuid_cliente': 'm7',
                'solicitud_id': 5,
                'autor_rol': 'proveedor',
                'propio': false,
                'texto': 'Empezamos.',
                'leido_en': null,
                'creado_en': '2026-11-24T12:03:45+00:00',
              },
              {
                'id': 8,
                'uuid_cliente': 'm8',
                'solicitud_id': 5,
                'autor_rol': 'cliente',
                'propio': true,
                'texto': 'Gracias.',
                'leido_en': null,
                'creado_en': '2026-11-24T13:03:45+00:00',
              },
            ],
            'cursor': 8,
            'solo_lectura': false,
          },
        );
        final pagina = await SeguimientoRed(
          red.http,
        ).mensajes('5', despues: '6');
        expect(pagina.mensajes.map((m) => m.propio), [false, true]);
        expect(pagina.cursor, '8');
        expect(pagina.soloLectura, isFalse);
        final peticion = red.servidor
            .de('GET', '/api/solicitudes/5/mensajes')
            .single;
        expect(peticion.query['despues'], '6');
      },
    );

    test(
      'enviar manda el texto y la clave; el servidor devuelve el mensaje',
      () async {
        final red = EntornoRed();
        red.servidor.responder(
          'POST',
          '/api/solicitudes/5/mensajes',
          codigo: 201,
          cuerpo: {
            'mensaje': {
              'id': 9,
              'uuid_cliente': 'clave-9',
              'solicitud_id': 5,
              'autor_rol': 'cliente',
              'propio': true,
              'texto': 'Hola',
              'leido_en': null,
              'creado_en': '2026-11-24T14:00:00+00:00',
            },
          },
        );
        final m = await SeguimientoRed(
          red.http,
        ).enviarMensaje('5', texto: ' Hola ', claveCliente: 'clave-9');
        expect(m.id, '9');
        expect(m.propio, isTrue);
        final cuerpo =
            red.servidor
                    .de('POST', '/api/solicitudes/5/mensajes')
                    .single
                    .cuerpo!
                as Map;
        expect(cuerpo['texto'], 'Hola');
        expect(cuerpo['uuid_cliente'], 'clave-9');
      },
    );

    test('con el chat cerrado el envío lanza ChatCerrado', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/5/mensajes',
        codigo: 409,
        cuerpo: {'message': 'El chat se cerró.', 'codigo': 'chat_cerrado'},
      );
      await expectLater(
        SeguimientoRed(
          red.http,
        ).enviarMensaje('5', texto: 'Hola', claveCliente: 'k'),
        throwsA(isA<ChatCerrado>()),
      );
    });

    test('marcar leídos manda el cursor como entero', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'POST',
        '/api/solicitudes/5/mensajes/leidos',
        cuerpo: {},
      );
      await SeguimientoRed(red.http).marcarLeidos('5', '8');
      expect(
        (red.servidor
                .de('POST', '/api/solicitudes/5/mensajes/leidos')
                .single
                .cuerpo!
            as Map)['hasta'],
        8,
      );
    });

    test('sin red todo falla con SinConexion', () async {
      final red = EntornoRed();
      red.servidor.sinRed = true;
      await expectLater(
        SeguimientoRed(red.http).avance('5'),
        throwsA(isA<SinConexion>()),
      );
    });
  });
}
