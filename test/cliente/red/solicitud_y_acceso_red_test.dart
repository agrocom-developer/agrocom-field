import 'package:agrocom_field/cliente/acceso/data/acceso_red.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_red.dart';
import 'package:agrocom_field/cliente/solicitar/domain/solicitud_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_red.dart';

class _OnboardingEnMemoria implements OnboardingStore {
  bool _visto = false;

  @override
  Future<bool> visto() async => _visto;

  @override
  Future<void> marcar() async => _visto = true;
}

const _estimacion = {
  'estimacion': {
    'congelada': false,
    'tarifa_base_hectarea': '120.0000',
    'tarifa_hectarea': '132.0000',
    'hectareas': '80.0000',
    'subtotal_base': '9600.00',
    'recargo_urgente': '1920.00',
    'monto_estimado': '11520.00',
  },
};

void main() {
  group('SolicitudRed', () {
    late EntornoRed red;
    late SolicitudRed repo;
    late Lote lote;

    setUp(() async {
      red = EntornoRed();
      red.servidor
        ..responder('GET', '/api/zonas', cuerpo: zonasJson)
        ..responder(
          'GET',
          '/api/terrenos',
          cuerpo: {
            'terrenos': [terrenoJson()],
          },
        )
        ..responder(
          'POST',
          '/api/solicitudes',
          codigo: 201,
          cuerpo: {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'borrador',
              proveedorId: null,
              montoFinal: null,
            ),
          },
        )
        ..responder(
          'GET',
          '/api/solicitudes/31/estimacion',
          cuerpo: _estimacion,
        )
        ..responder(
          'POST',
          '/api/solicitudes/31/publicar',
          cuerpo: {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'publicada',
              proveedorId: null,
              montoFinal: null,
            ),
          },
        )
        ..responder(
          'GET',
          '/api/solicitudes',
          cuerpo: {'solicitudes': [], 'pagina': 1, 'paginas': 1, 'total': 0},
        );
      repo = SolicitudRed(
        red.http,
        red.fuente,
        reloj: () => DateTime(2026, 11, 24, 9),
        pasoBusqueda: Duration.zero,
      );
      lote = (await repo.lotesDelCliente()).single;
    });

    SolicitudServicio solicitud({String clave = 'clave-1'}) =>
        SolicitudServicio(
          lote: lote,
          producto: 'Glifosato 480 SL',
          dosisLitrosPorHectarea: Decimal.parse('2'),
          fechaDeseada: DateTime(2026, 11, 25),
          claveIdempotencia: clave,
          hectareas: Decimal.parse('80'),
          cultivo: 'Soya',
          ventana: VentanaHoraria.amanecer,
        );

    test('los lotes son los terrenos del cliente con su zona', () {
      expect(lote.id, '1');
      expect(lote.nombre, 'Lote Norte');
      expect(lote.zona, 'Cuatro Cañadas');
      expect(lote.hectareas, Decimal.parse('80'));
      expect(lote.poligono.length, greaterThanOrEqualTo(3));
    });

    test('estimar crea un borrador y lee la tarifa de ese borrador', () async {
      final s = solicitud();
      final e = await repo.estimar(
        lote: lote,
        dosisLitrosPorHectarea: s.dosisLitrosPorHectarea,
        hectareas: s.hectareas,
        fechaDeseada: s.fechaDeseada,
        producto: s.producto,
        cultivo: s.cultivo,
        ventana: s.ventana,
        claveIdempotencia: s.claveIdempotencia,
      );
      expect(e.precio, Decimal.parse('11520.00'));
      expect(e.recargos.single.concepto, contains('urgencia'));
      final cuerpo =
          red.servidor.de('POST', '/api/solicitudes').single.cuerpo! as Map;
      expect(cuerpo['terreno_id'], 1);
      expect(cuerpo['tipo_aplicacion'], 'herbicida');
      expect(cuerpo['hectareas_solicitadas'], '80');
      expect(cuerpo['producto_indicado'], 'Glifosato 480 SL, 2 L/ha');
      expect(cuerpo['ventana_desde'], '2026-11-25');
      expect(cuerpo['ventana_hasta'], '2026-12-02');
      expect(cuerpo['urgente'], isTrue);
      expect(cuerpo['observaciones'], contains('Amanecer'));
    });

    test('solicitar publica el mismo borrador que se estimó', () async {
      final s = solicitud();
      await repo.estimar(
        lote: lote,
        dosisLitrosPorHectarea: s.dosisLitrosPorHectarea,
        hectareas: s.hectareas,
        fechaDeseada: s.fechaDeseada,
        producto: s.producto,
        cultivo: s.cultivo,
        ventana: s.ventana,
        claveIdempotencia: s.claveIdempotencia,
      );
      final servicio = await repo.solicitar(s);
      expect(servicio.id, '31');
      expect(servicio.estado, EstadoServicio.buscandoProveedor);
      expect(red.servidor.de('POST', '/api/solicitudes'), hasLength(1));
      expect(
        red.servidor.de('POST', '/api/solicitudes/31/publicar'),
        hasLength(1),
      );
    });

    test('el mismo envío reintentado manda el mismo uuid_cliente', () async {
      final a = solicitud();
      await repo.solicitar(a);
      // Otra instancia (la app se reinició): mismo dato, misma clave.
      final otra = SolicitudRed(red.http, red.fuente);
      await otra.solicitar(a);
      final uuids = red.servidor
          .de('POST', '/api/solicitudes')
          .map((p) => (p.cuerpo! as Map)['uuid_cliente'])
          .toSet();
      expect(uuids, hasLength(1));
    });

    test(
      'sin red, solicitar lanza SolicitudSinConexion y se puede reintentar',
      () async {
        red.servidor.sinRed = true;
        await expectLater(
          repo.solicitar(solicitud()),
          throwsA(isA<SolicitudSinConexion>()),
        );
        red.servidor.sinRed = false;
        expect((await repo.solicitar(solicitud())).id, '31');
      },
    );

    test('si la publicación ya había llegado, el reintento no falla', () async {
      await repo.solicitar(solicitud());
      red.servidor
        ..responder(
          'POST',
          '/api/solicitudes/31/publicar',
          codigo: 422,
          cuerpo: {'message': 'La solicitud ya fue publicada.'},
        )
        ..responder(
          'GET',
          '/api/solicitudes/31',
          cuerpo: {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'en_asignacion',
              proveedorId: null,
              montoFinal: null,
            ),
          },
        );
      // Otra instancia con el mismo dato: el borrador se vuelve a pedir y
      // la publicación repetida se resuelve leyendo la solicitud.
      final servicio = await SolicitudRed(
        red.http,
        red.fuente,
      ).solicitar(solicitud());
      expect(servicio.id, '31');
    });

    test('un contorno dibujado crea primero el terreno', () async {
      red.servidor.responder(
        'POST',
        '/api/terrenos',
        codigo: 201,
        cuerpo: {'terreno': terrenoJson(id: 44)},
      );
      final dibujado = Lote(
        id: 'lote-clave-1',
        nombre: 'Lote nuevo',
        zona: 'Contorno dibujado',
        cultivo: 'Maíz',
        hectareas: Decimal.parse('12.5'),
        poligono: const [
          GeoPunto(-17.0, -62.0),
          GeoPunto(-17.0, -61.99),
          GeoPunto(-16.99, -61.99),
        ],
      );
      await repo.solicitar(
        SolicitudServicio(
          lote: dibujado,
          producto: 'Fertilizante foliar',
          dosisLitrosPorHectarea: Decimal.one,
          fechaDeseada: DateTime(2026, 12, 1),
          claveIdempotencia: 'clave-2',
          hectareas: Decimal.parse('12.5'),
        ),
      );
      final terreno =
          red.servidor.de('POST', '/api/terrenos').single.cuerpo! as Map;
      expect(terreno['hectareas'], '12.5');
      expect((terreno['geometria'] as Map)['type'], 'Polygon');
      final solicitud =
          red.servidor.de('POST', '/api/solicitudes').single.cuerpo! as Map;
      expect(solicitud['terreno_id'], 44);
      expect(solicitud['tipo_aplicacion'], 'fertilizante_foliar');
    });

    test('la búsqueda sigue la solicitud hasta que se asigna', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/31',
        secuencia: [
          {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'en_asignacion',
              proveedorId: null,
              montoFinal: null,
            ),
          },
          {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'asignada',
              montoFinal: null,
            ),
          },
        ],
        cuerpo: null,
      );
      final fases = await repo.observarBusqueda('31').toList();
      expect(fases.map((b) => b.fase), [
        FaseBusqueda.propios,
        FaseBusqueda.asignado,
      ]);
      expect(fases.last.proveedor, isNotNull);
    });

    test('sin proveedor termina la búsqueda', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/31',
        cuerpo: {
          'solicitud': solicitudJson(
            id: 31,
            estado: 'sin_proveedor',
            proveedorId: null,
            montoFinal: null,
          ),
        },
      );
      final fases = await repo.observarBusqueda('31').toList();
      expect(fases.single.fase, FaseBusqueda.sinProveedor);
    });
  });

  group('AccesoRed', () {
    late EntornoRed red;
    late AccesoRed acceso;
    late _OnboardingEnMemoria onboarding;
    var sesionesCerradas = 0;

    const cuerpoToken = {
      'token': '6|secreto',
      'token_type': 'Bearer',
      'usuario': {
        'id': 20,
        'name': 'Rosario Antelo Vaca',
        'username': 'agro.sanrafael',
        'persona_id': null,
      },
      'rol': {'id': 6, 'name': 'cliente', 'description': 'Cliente'},
      'dispositivo': {},
    };

    setUp(() {
      sesionesCerradas = 0;
      red = EntornoRed(token: null);
      onboarding = _OnboardingEnMemoria();
      red.servidor
        ..responder(
          'GET',
          '/api/auth/sesion',
          cuerpo: {
            'usuario': cuerpoToken['usuario'],
            'rol': cuerpoToken['rol'],
            'dispositivo': {},
          },
        )
        ..responder(
          'GET',
          '/api/clientes/mi',
          cuerpo: {
            'cliente': {
              'id': 1,
              'tipo': 'empresa',
              'razon_social': 'Agropecuaria San Rafael SRL',
              'telefono': '+591 76543210',
            },
          },
        )
        ..responder('DELETE', '/api/auth/token', codigo: 204, cuerpo: {});
      acceso = AccesoRed(
        api: red.api,
        tokenStore: red.tokens,
        dispositivoStore: DispositivoFijo(),
        onboarding: onboarding,
        alCerrarSesion: () => sesionesCerradas++,
      );
    });

    test('entra con usuario y contraseña y guarda el token', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 201,
        cuerpo: cuerpoToken,
      );
      final sesion = await acceso.iniciarSesion(
        usuario: 'agro.sanrafael',
        contrasena: '0000',
      );
      expect(sesion.nombre, 'Rosario Antelo Vaca');
      expect(sesion.primerNombre, 'Rosario');
      expect(sesion.usuario, 'agro.sanrafael');
      expect(sesion.empresa, 'Agropecuaria San Rafael SRL');
      expect(red.tokens.token, '6|secreto');
      final pedido =
          red.servidor.de('POST', '/api/auth/token').single.cuerpo! as Map;
      expect(pedido['username'], 'agro.sanrafael');
      expect(
        pedido['uuid_dispositivo'],
        '11111111-1111-4111-8111-111111111111',
      );
      expect(pedido.containsKey('role_id'), isFalse);
      expect(pedido.containsKey('correo'), isFalse);
    });

    test('credenciales incorrectas (422) no guardan nada', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 422,
        cuerpo: {
          'message': 'Las credenciales no coinciden con ningún registro.',
        },
      );
      await expectLater(
        acceso.iniciarSesion(usuario: 'x.y', contrasena: 'mal'),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.motivo,
            'motivo',
            MotivoFalloAcceso.credencialesInvalidas,
          ),
        ),
      );
      expect(red.tokens.token, isNull);
    });

    test('sin red lo dice y conserva lo escrito', () async {
      red.servidor.sinRed = true;
      await expectLater(
        acceso.iniciarSesion(usuario: 'x.y', contrasena: 'mal'),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.motivo,
            'motivo',
            MotivoFalloAcceso.sinConexion,
          ),
        ),
      );
    });

    test('con varios roles entra con el de cliente', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        secuencia: [
          (
            409,
            {
              'message': 'Elige un rol',
              'roles': [
                {'id': 2, 'name': 'piloto'},
                {'id': 6, 'name': 'cliente'},
              ],
            },
          ),
          (201, cuerpoToken),
        ],
      );
      final sesion = await acceso.iniciarSesion(
        usuario: 'x.y',
        contrasena: '0000',
      );
      expect(sesion.usuario, 'agro.sanrafael');
      final intentos = red.servidor.de('POST', '/api/auth/token').toList();
      expect(intentos, hasLength(2));
      expect((intentos.last.cuerpo! as Map)['role_id'], 6);
    });

    test('una cuenta sin rol de cliente no entra', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 409,
        cuerpo: {
          'message': 'Elige un rol',
          'roles': [
            {'id': 2, 'name': 'piloto'},
          ],
        },
      );
      await expectLater(
        acceso.iniciarSesion(usuario: 'rodrigo.suarez', contrasena: '0000'),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.porCampo[CampoAcceso.usuario],
            'mensaje',
            contains('no es de cliente'),
          ),
        ),
      );
      expect(red.tokens.token, isNull);
    });

    test('un token de otro rol se revoca y no queda guardado', () async {
      red.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 201,
        cuerpo: {
          ...cuerpoToken,
          'rol': {'id': 2, 'name': 'piloto'},
        },
      );
      await expectLater(
        acceso.iniciarSesion(usuario: 'rodrigo.suarez', contrasena: '0000'),
        throwsA(isA<AccesoExcepcion>()),
      );
      expect(red.tokens.token, isNull);
      expect(red.servidor.de('DELETE', '/api/auth/token'), hasLength(1));
    });

    test('registrar crea la cuenta y entra', () async {
      red.servidor
        ..responder(
          'POST',
          '/api/clientes/registro',
          codigo: 201,
          cuerpo: {'cliente': {}},
        )
        ..responder(
          'POST',
          '/api/auth/token',
          codigo: 201,
          cuerpo: cuerpoToken,
        );
      final sesion = await acceso.registrar(
        const DatosRegistroCliente(
          nombre: ' Rosa Condori ',
          telefono: '+591 76543210',
          usuario: 'rosa.condori',
          contrasena: 'clave1234',
        ),
      );
      expect(sesion.usuario, 'agro.sanrafael');
      final cuerpo =
          red.servidor.de('POST', '/api/clientes/registro').single.cuerpo!
              as Map;
      expect(cuerpo['tipo'], 'persona');
      expect(cuerpo['nombre'], 'Rosa Condori');
      expect(cuerpo['username'], 'rosa.condori');
      expect(cuerpo['password'], 'clave1234');
    });

    test('registrar con un usuario ocupado marca el campo', () async {
      red.servidor.responder(
        'POST',
        '/api/clientes/registro',
        codigo: 422,
        cuerpo: {
          'message': 'El username ya está en uso.',
          'errors': {
            'username': ['El username ya está en uso.'],
            'password': ['La contraseña es muy corta.'],
            'email': ['Otro campo'],
          },
        },
      );
      await expectLater(
        acceso.registrar(
          const DatosRegistroCliente(
            nombre: 'Rosa',
            telefono: '1234567',
            usuario: 'rosa.condori',
            contrasena: 'clave1234',
          ),
        ),
        throwsA(
          isA<AccesoExcepcion>()
              .having((e) => e.motivo, 'motivo', MotivoFalloAcceso.validacion)
              .having((e) => e.porCampo.keys, 'campos', [
                CampoAcceso.usuario,
                CampoAcceso.contrasena,
              ]),
        ),
      );
    });

    test('sesionActual: sin token es null; con token lee la sesión', () async {
      expect(await acceso.sesionActual(), isNull);
      red.tokens.token = 'tok';
      final sesion = await acceso.sesionActual();
      expect(sesion?.usuario, 'agro.sanrafael');
    });

    test('sesionActual con un token vencido lo borra', () async {
      red.tokens.token = 'vencido';
      red.servidor.responder(
        'GET',
        '/api/auth/sesion',
        codigo: 401,
        cuerpo: {},
      );
      expect(await acceso.sesionActual(), isNull);
      expect(red.tokens.token, isNull);
    });

    test('cerrar sesión revoca el dispositivo y borra el token', () async {
      red.tokens.token = 'tok';
      await acceso.cerrarSesion();
      expect(red.tokens.token, isNull);
      expect(red.servidor.de('DELETE', '/api/auth/token'), hasLength(1));
      expect(sesionesCerradas, 1);
    });

    test('cerrar sesión sin red borra el token igual', () async {
      red.tokens.token = 'tok';
      red.servidor.sinRed = true;
      await acceso.cerrarSesion();
      expect(red.tokens.token, isNull);
      expect(sesionesCerradas, 1);
    });

    test('la presentación se recuerda', () async {
      expect(await acceso.onboardingVisto(), isFalse);
      await acceso.marcarOnboardingVisto();
      expect(await acceso.onboardingVisto(), isTrue);
    });
  });

  group('DependenciasCliente.red', () {
    test('un 401 borra el token y avisa que la sesión venció', () async {
      final red = EntornoRed(token: 'viejo');
      red.servidor.responder(
        'GET',
        '/api/solicitudes',
        codigo: 401,
        cuerpo: {},
      );
      red.servidor.responder('GET', '/api/zonas', cuerpo: zonasJson);
      final deps = DependenciasCliente.red(
        api: red.api,
        tokenStore: red.tokens,
        dispositivoStore: DispositivoFijo(),
        onboarding: _OnboardingEnMemoria(),
      );
      final avisos = <void>[];
      final sub = deps.sesionExpirada!.listen(avisos.add);
      await expectLater(
        deps.servicios.observar().first,
        throwsA(isA<OperacionRechazada>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(avisos, hasLength(1));
      expect(red.tokens.token, isNull);
      await sub.cancel();
    });
  });
}
