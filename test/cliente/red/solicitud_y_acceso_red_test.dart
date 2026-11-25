import 'package:agrocom_field/cliente/acceso/data/acceso_red.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
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
              ofertaAdjudicadaId: null,
              precioAcordado: null,
              montoFinal: null,
              ejecutadas: null,
              porcentaje: '0.00',
            ),
          },
        )
        ..responder(
          'POST',
          '/api/solicitudes/31/publicar',
          cuerpo: {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'abierta',
              proveedorId: null,
              ofertaAdjudicadaId: null,
              precioAcordado: null,
              montoFinal: null,
              ejecutadas: null,
              porcentaje: '0.00',
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
      );
      lote = (await repo.lotesDelCliente()).single;
    });

    NuevaSolicitud nueva({String clave = 'clave-1', String precio = '121.5'}) =>
        NuevaSolicitud(
          lote: lote,
          hectareas: Decimal.parse('60'),
          cultivo: 'Soya',
          producto: 'Glifosato 480 SL',
          fechaDeseada: DateTime(2026, 11, 25),
          precioHa: Decimal.parse(precio),
          claveIdempotencia: clave,
          observaciones: 'Hay una línea eléctrica al sur',
        );

    test('lee los terrenos del cliente como lotes con su zona', () {
      expect(lote.id, '1');
      expect(lote.zona, 'Cuatro Cañadas');
      expect(lote.hectareas, Decimal.parse('80'));
    });

    test('crea el borrador con el precio propuesto y lo publica', () async {
      final solicitud = await repo.publicar(nueva());
      expect(solicitud.id, '31');
      expect(solicitud.estado, EstadoSolicitud.abierta);
      final borrador =
          red.servidor.de('POST', '/api/solicitudes').single.cuerpo! as Map;
      expect(borrador['terreno_id'], 1);
      expect(borrador['hectareas_solicitadas'], '60');
      expect(borrador['precio_ha_propuesto'], '121.5');
      expect(borrador['producto_indicado'], 'Glifosato 480 SL');
      expect(borrador['tipo_aplicacion'], 'herbicida');
      expect(borrador['ventana_desde'], '2026-11-25');
      expect(borrador['ventana_hasta'], '2026-11-28');
      expect(borrador['observaciones'], 'Hay una línea eléctrica al sur');
      expect(borrador['urgente'], isTrue);
      expect(
        red.servidor.de('POST', '/api/solicitudes/31/publicar'),
        hasLength(1),
      );
      // Ya no existe estimación de tarifa: el precio lo negocian las partes.
      expect(red.servidor.de('GET', '/api/solicitudes/31/estimacion'), isEmpty);
    });

    test('un reintento con los mismos datos manda el mismo uuid', () async {
      await repo.publicar(nueva());
      await repo.publicar(nueva());
      final uuids = red.servidor
          .de('POST', '/api/solicitudes')
          .map((p) => (p.cuerpo! as Map)['uuid_cliente'])
          .toSet();
      expect(uuids, hasLength(1));
    });

    test('cambiar el precio crea otro borrador con otro uuid', () async {
      await repo.publicar(nueva());
      await repo.publicar(nueva(precio: '130'));
      final uuids = red.servidor
          .de('POST', '/api/solicitudes')
          .map((p) => (p.cuerpo! as Map)['uuid_cliente'])
          .toSet();
      expect(uuids, hasLength(2));
    });

    test('si la publicación ya había llegado, devuelve la solicitud', () async {
      red.servidor
        ..responder(
          'POST',
          '/api/solicitudes/31/publicar',
          codigo: 422,
          cuerpo: {'message': 'La solicitud ya no está en borrador.'},
        )
        ..responder(
          'GET',
          '/api/solicitudes/31',
          cuerpo: {
            'solicitud': solicitudJson(
              id: 31,
              estado: 'abierta',
              proveedorId: null,
              ofertaAdjudicadaId: null,
              precioAcordado: null,
              montoFinal: null,
              ejecutadas: null,
              porcentaje: '0.00',
            ),
          },
        );
      final solicitud = await repo.publicar(nueva());
      expect(solicitud.estado, EstadoSolicitud.abierta);
    });

    test(
      'un borrador que el servidor no deja publicar falla con su motivo',
      () async {
        red.servidor
          ..responder(
            'POST',
            '/api/solicitudes/31/publicar',
            codigo: 422,
            cuerpo: {'message': 'Falta un teléfono en tu cuenta.'},
          )
          ..responder(
            'GET',
            '/api/solicitudes/31',
            cuerpo: {
              'solicitud': solicitudJson(
                id: 31,
                estado: 'borrador',
                proveedorId: null,
                ofertaAdjudicadaId: null,
                precioAcordado: null,
                montoFinal: null,
                ejecutadas: null,
                porcentaje: '0.00',
              ),
            },
          );
        await expectLater(
          repo.publicar(nueva()),
          throwsA(
            isA<OperacionRechazada>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('teléfono'),
            ),
          ),
        );
      },
    );

    test('un contorno dibujado primero se guarda como terreno', () async {
      red.servidor.responder(
        'POST',
        '/api/terrenos',
        codigo: 201,
        cuerpo: {'terreno': terrenoJson(id: 77)},
      );
      final dibujado = Lote(
        id: 'lote-clave',
        nombre: 'Lote nuevo',
        zona: 'Contorno dibujado',
        cultivo: 'Soya',
        hectareas: Decimal.parse('45.5'),
        poligono: const [
          GeoPunto(-17.0, -62.0),
          GeoPunto(-17.0, -61.9),
          GeoPunto(-16.9, -61.9),
        ],
      );
      await repo.publicar(
        NuevaSolicitud(
          lote: dibujado,
          hectareas: Decimal.parse('45.5'),
          cultivo: 'Soya',
          producto: 'Insecticida piretroide',
          fechaDeseada: DateTime(2026, 11, 28),
          precioHa: Decimal.parse('110'),
          claveIdempotencia: 'k2',
          accesos: 'Portón azul',
        ),
      );
      final terreno =
          red.servidor.de('POST', '/api/terrenos').single.cuerpo! as Map;
      expect(terreno['hectareas'], '45.5');
      expect(terreno['referencias_acceso'], 'Portón azul');
      expect((terreno['geometria'] as Map)['type'], 'Polygon');
      final solicitud =
          red.servidor.de('POST', '/api/solicitudes').single.cuerpo! as Map;
      expect(solicitud['terreno_id'], 77);
      // Otra publicación con el mismo contorno no crea otro terreno.
      await repo.publicar(
        NuevaSolicitud(
          lote: dibujado,
          hectareas: Decimal.parse('45.5'),
          cultivo: 'Soya',
          producto: 'Insecticida piretroide',
          fechaDeseada: DateTime(2026, 11, 28),
          precioHa: Decimal.parse('112'),
          claveIdempotencia: 'k2',
        ),
      );
      expect(red.servidor.de('POST', '/api/terrenos'), hasLength(1));
    });

    test(
      'sin red lanza SolicitudSinConexion y conserva el reintento',
      () async {
        red.servidor.sinRed = true;
        await expectLater(
          repo.publicar(nueva()),
          throwsA(isA<SolicitudSinConexion>()),
        );
        red.servidor.sinRed = false;
        final solicitud = await repo.publicar(nueva());
        expect(solicitud.id, '31');
      },
    );
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

    test(
      'asociar una empresa envía razón social, NIT y al registrante como contacto principal',
      () async {
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
        await acceso.registrar(
          const DatosRegistroCliente(
            nombre: 'Rosa Condori',
            telefono: '+591 76543210',
            usuario: 'rosa.condori',
            contrasena: 'clave1234',
            tipo: TipoCliente.empresa,
            razonSocial: ' Agropecuaria San Rafael SRL ',
            documentoFiscal: '1029384027',
            cargo: 'Encargada de campo',
          ),
        );
        final cuerpo =
            red.servidor.de('POST', '/api/clientes/registro').single.cuerpo!
                as Map;
        expect(cuerpo['tipo'], 'empresa');
        expect(cuerpo['razon_social'], 'Agropecuaria San Rafael SRL');
        expect(cuerpo['documento_fiscal'], '1029384027');
        expect(cuerpo['contactos'], [
          {
            'nombre': 'Rosa Condori',
            'telefono': '+591 76543210',
            'cargo': 'Encargada de campo',
            'es_principal': true,
          },
        ]);
      },
    );

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
        deps.solicitudes.observar().first,
        throwsA(isA<OperacionRechazada>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(avisos, hasLength(1));
      expect(red.tokens.token, isNull);
      await sub.cancel();
    });
  });
}
