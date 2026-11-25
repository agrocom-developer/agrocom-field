import 'package:agrocom_field/l10n/app_localizations_es.dart';
// Acceso y alta del proveedor, compresión de fotos y ubicación del piloto.

import 'dart:async';
import 'dart:typed_data';

import 'package:agrocom_field/nucleo/api/marketplace_http.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/camara/selector_imagen.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_adaptativo.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/data/acceso_proveedor_red.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/domain/acceso_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/acceso_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/registro_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/data/ejecucion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/domain/ejecucion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/presentation/ejecucion_cubits.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../cliente/red/dobles_red.dart';

class _AccesoFalso implements AccesoProveedorRepositorio {
  SesionProveedor? sesion;
  Object? falla;
  final llamadas = <String>[];
  int sesionesPedidas = 0;

  @override
  Future<SesionProveedor?> sesionActual() async => sesion;

  @override
  Future<SesionProveedor> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    llamadas.add('sesion');
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
    return sesion = SesionProveedor(
      nombre: 'Carlos Mamani',
      usuario: usuario,
      rol: 'proveedor',
    );
  }

  @override
  Future<void> registrar(DatosPersona datos) async {
    llamadas.add('registrar');
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
  }

  @override
  Future<void> cerrarSesion() async => sesion = null;
}

class _DronesFalso implements RegistroDronesRepositorio {
  final llamadas = <String>[];
  Object? fallaAlSubir;

  @override
  Future<int> registrarDron(DatosDron datos) async {
    llamadas.add('dron');
    return 4;
  }

  @override
  Future<void> subirFoto(int dronId, FotoDronLista foto) async {
    final f = fallaAlSubir;
    if (f != null) {
      fallaAlSubir = null;
      throw f;
    }
    llamadas.add('foto:${foto.tipo.codigo}');
  }
}

class _SelectorFalso implements SelectorImagen {
  @override
  Future<Uint8List?> tomarFoto() async => Uint8List.fromList([1, 2, 3]);

  @override
  Future<Uint8List?> elegirDeGaleria() async => Uint8List.fromList([4, 5, 6]);
}

class _CompresorIdentidad implements CompresorEvidencia {
  @override
  Future<Uint8List> comprimir(Uint8List bytes) async => bytes;
}

final _persona = DatosPersona(
  nombres: 'Carlos',
  apellidos: 'Mamani',
  documentoIdentidad: '123',
  fechaNacimiento: DateTime(1990),
  telefono: '70012345',
  usuario: 'carlos.mamani',
  contrasena: '0000abcd',
  licenciaNumero: 'L-1',
  licenciaVence: DateTime(2027),
  categoriaHabilitacion: 'A',
);

final _dron = DatosDron(
  marca: 'DJI',
  modelo: 'Agras T40',
  numeroSerie: 'SN1',
  capacidadTanqueL: Decimal.parse('40'),
  anchoPasadaM: Decimal.parse('11'),
);

void main() {
  group('acceso real', () {
    late EntornoRed e;
    late AccesoProveedorRed acceso;

    AccesoProveedorRed crear(List<String> roles) => AccesoProveedorRed(
      api: e.api,
      tokenStore: e.tokens,
      dispositivoStore: DispositivoFijo(),
      rolesPreferidos: roles,
      nombreDispositivo: 'Agrocom Piloto',
    );

    Map<String, dynamic> token(String rol) => {
      'token': 'abc',
      'usuario': {'id': 9, 'name': 'Carlos Mamani', 'username': 'carlos'},
      'rol': {'id': 7, 'name': rol},
    };

    setUp(() {
      e = EntornoRed(token: null);
      acceso = crear(['proveedor', 'piloto']);
    });

    test(
      'guarda el token en almacenamiento seguro y no la contraseña',
      () async {
        e.servidor.responder(
          'POST',
          '/api/auth/token',
          codigo: 201,
          cuerpo: token('proveedor'),
        );
        final s = await acceso.iniciarSesion(
          usuario: ' carlos.mamani ',
          contrasena: '0000',
        );
        expect(s.rol, 'proveedor');
        expect(e.tokens.token, 'abc');
        final cuerpo =
            e.servidor.de('POST', '/api/auth/token').single.cuerpo! as Map;
        expect(cuerpo['username'], 'carlos.mamani');
        expect(cuerpo['nombre_dispositivo'], 'Agrocom Piloto');
      },
    );

    test('con dos roles elige primero proveedor y luego piloto', () async {
      e.servidor.responder(
        'POST',
        '/api/auth/token',
        secuencia: [
          (
            409,
            {
              'message': 'Debes indicar con qué rol opera.',
              'roles': [
                {'id': 1, 'name': 'piloto'},
                {'id': 7, 'name': 'proveedor'},
              ],
            },
          ),
          (201, token('proveedor')),
        ],
      );
      await acceso.iniciarSesion(usuario: 'carlos', contrasena: '0000');
      final enviados = e.servidor.de('POST', '/api/auth/token').toList();
      expect((enviados.last.cuerpo! as Map)['role_id'], 7);
    });

    test('el auxiliar no entra con una cuenta de piloto', () async {
      e.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 201,
        cuerpo: token('piloto'),
      );
      e.servidor.responder('DELETE', '/api/auth/token', codigo: 204);
      await expectLater(
        crear(['auxiliar']).iniciarSesion(usuario: 'x', contrasena: 'y'),
        throwsA(
          isA<AccesoProveedorExcepcion>().having(
            (x) => x.motivo,
            'motivo',
            MotivoFalloAcceso.cuentaAjena,
          ),
        ),
      );
      expect(e.tokens.token, isNull);
    });

    test('credenciales malas y sin red se distinguen', () async {
      e.servidor.responder('POST', '/api/auth/token', codigo: 401, cuerpo: {});
      await expectLater(
        acceso.iniciarSesion(usuario: 'x', contrasena: 'mala'),
        throwsA(
          isA<AccesoProveedorExcepcion>().having(
            (x) => x.motivo,
            'motivo',
            MotivoFalloAcceso.credencialesInvalidas,
          ),
        ),
      );
      e.servidor.sinRed = true;
      await expectLater(
        acceso.iniciarSesion(usuario: 'x', contrasena: 'y'),
        throwsA(
          isA<AccesoProveedorExcepcion>().having(
            (x) => x.motivo,
            'motivo',
            MotivoFalloAcceso.sinConexion,
          ),
        ),
      );
    });

    test('cerrar sesión borra el token aunque no haya red', () async {
      e.tokens.token = 'abc';
      e.servidor.sinRed = true;
      var limpio = false;
      final a = AccesoProveedorRed(
        api: e.api,
        tokenStore: e.tokens,
        dispositivoStore: DispositivoFijo(),
        rolesPreferidos: const ['piloto'],
        nombreDispositivo: 'x',
        alCerrarSesion: () async => limpio = true,
      );
      await a.cerrarSesion();
      expect(e.tokens.token, isNull);
      expect(limpio, isTrue);
    });

    test(
      'el registro manda los datos de la persona, de la licencia y fechas',
      () async {
        e.servidor.responder(
          'POST',
          '/api/proveedores/registro',
          codigo: 201,
          cuerpo: {'proveedor': {}},
        );
        await acceso.registrar(_persona);
        final c =
            e.servidor.de('POST', '/api/proveedores/registro').single.cuerpo!
                as Map;
        expect(c['tipo'], 'independiente');
        expect(c['fecha_nacimiento'], '1990-01-01');
        expect(c['licencia_vence'], '2027-01-01');
        // Sin razón social ni documento fiscal, se usan el nombre y el carnet.
        expect(c['razon_social'], 'Carlos Mamani');
        expect(c['documento_fiscal'], '123');
      },
    );

    test('un 422 devuelve los errores por campo', () async {
      e.servidor.responder(
        'POST',
        '/api/proveedores/registro',
        codigo: 422,
        cuerpo: {
          'message': 'Ese usuario ya existe.',
          'errors': {
            'username': ['Ese usuario ya existe.'],
          },
        },
      );
      await expectLater(
        acceso.registrar(_persona),
        throwsA(
          isA<AccesoProveedorExcepcion>().having(
            (x) => x.porCampo['username'],
            'username',
            'Ese usuario ya existe.',
          ),
        ),
      );
    });

    test('el dron y sus fotos se suben con sus tipos', () async {
      e.servidor.responder(
        'POST',
        '/api/proveedores/drones',
        codigo: 201,
        cuerpo: {
          'dron': {'id': 4},
        },
      );
      e.servidor.responder(
        'POST',
        '/api/proveedores/drones/4/fotos',
        codigo: 201,
        cuerpo: {'foto': {}},
      );
      final repo = RegistroDronesRed(MarketplaceHttp(e.api));
      final id = await repo.registrarDron(_dron);
      expect(id, 4);
      final cuerpo =
          e.servidor.de('POST', '/api/proveedores/drones').single.cuerpo!
              as Map;
      expect(cuerpo['capacidad_tanque_l'], '40');
      await repo.subirFoto(
        4,
        FotoDronLista(TipoFotoDron.frontal, Uint8List.fromList([1])),
      );
      final foto = e.servidor
          .de('POST', '/api/proveedores/drones/4/fotos')
          .single;
      expect((foto.cuerpo! as FormData).fields.single.value, 'frontal');
    });
  });

  group('puerta de acceso', () {
    test('sin sesión guardada muestra el ingreso', () async {
      final cubit = AccesoCubit(_AccesoFalso(), AppLocalizationsEs());
      await cubit.iniciar();
      expect(cubit.state, isA<AccesoSinSesion>());
      await cubit.close();
    });

    test('con sesión guardada entra directo', () async {
      final acceso = _AccesoFalso()
        ..sesion = const SesionProveedor(
          nombre: 'Rodrigo',
          usuario: 'rodrigo',
          rol: 'piloto',
        );
      final cubit = AccesoCubit(acceso, AppLocalizationsEs());
      await cubit.iniciar();
      expect(cubit.state, isA<AccesoDentro>());
      await cubit.close();
    });

    test('ingresar con error deja el mensaje y se puede reintentar', () async {
      final acceso = _AccesoFalso()
        ..falla = const AccesoProveedorExcepcion(
          MotivoFalloAcceso.credencialesInvalidas,
        );
      final cubit = AccesoCubit(acceso, AppLocalizationsEs());
      await cubit.ingresar('x', 'y');
      expect((cubit.state as AccesoSinSesion).mensaje, contains('incorrectos'));
      await cubit.ingresar('x', 'y');
      expect(cubit.state, isA<AccesoDentro>());
      await cubit.close();
    });

    test('un 401 en pleno uso vuelve al ingreso con el aviso', () async {
      final vencida = StreamController<void>();
      final acceso = _AccesoFalso()
        ..sesion = const SesionProveedor(
          nombre: 'R',
          usuario: 'r',
          rol: 'piloto',
        );
      final cubit = AccesoCubit(
        acceso,
        AppLocalizationsEs(),
        sesionExpirada: vencida.stream,
      );
      await cubit.iniciar();
      vencida.add(null);
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as AccesoSinSesion).sesionVencida, isTrue);
      await vencida.close();
      await cubit.close();
    });

    test('salir cierra la sesión', () async {
      final acceso = _AccesoFalso();
      final cubit = AccesoCubit(acceso, AppLocalizationsEs());
      await cubit.ingresar('x', 'y');
      await cubit.salir();
      expect(acceso.sesion, isNull);
      expect(cubit.state, isA<AccesoSinSesion>());
      await cubit.close();
    });
  });

  group('alta del proveedor', () {
    RegistroCubit crear(_AccesoFalso a, _DronesFalso d) => RegistroCubit(
      acceso: a,
      drones: d,
      selector: _SelectorFalso(),
      compresor: _CompresorIdentidad(),
      l10n: AppLocalizationsEs(),
    );

    Future<void> conTresFotos(RegistroCubit c) async {
      for (final t in TipoFotoDron.values.where((t) => t.obligatoria)) {
        await c.elegirFoto(t, deGaleria: t == TipoFotoDron.lateral);
      }
    }

    test(
      'las fotos obligatorias son frontal, lateral y placa de serie',
      () async {
        final c = crear(_AccesoFalso(), _DronesFalso());
        expect(c.state.fotosObligatoriasListas, isFalse);
        await conTresFotos(c);
        expect(c.state.fotosObligatoriasListas, isTrue);
        c.quitarFoto(TipoFotoDron.frontal);
        expect(c.state.fotosObligatoriasListas, isFalse);
        await c.close();
      },
    );

    test('cuenta, sesión, dron y fotos en ese orden', () async {
      final a = _AccesoFalso();
      final d = _DronesFalso();
      final c = crear(a, d);
      await conTresFotos(c);
      await c.enviar(_persona, _dron);
      expect(a.llamadas, ['registrar', 'sesion']);
      expect(d.llamadas, [
        'dron',
        'foto:frontal',
        'foto:lateral',
        'foto:placa_serie',
      ]);
      expect(c.state.terminado, isTrue);
      await c.close();
    });

    test(
      'si falla una foto, reintentar no repite la cuenta ni el dron',
      () async {
        final a = _AccesoFalso();
        final d = _DronesFalso()..fallaAlSubir = const SinConexion();
        final c = crear(a, d);
        await conTresFotos(c);
        await c.enviar(_persona, _dron);
        expect(c.state.terminado, isFalse);
        expect(c.state.mensaje, contains('Sin conexión'));
        expect(c.state.paso, PasoRegistro.fotos);
        await c.enviar(_persona, _dron);
        expect(a.llamadas, ['registrar', 'sesion']);
        expect(d.llamadas.where((x) => x == 'dron'), hasLength(1));
        expect(d.llamadas.where((x) => x.startsWith('foto')), hasLength(3));
        expect(c.state.terminado, isTrue);
        await c.close();
      },
    );

    test(
      'un error por campo se conserva para marcarlo en el formulario',
      () async {
        final a = _AccesoFalso()
          ..falla = const AccesoProveedorExcepcion(
            MotivoFalloAcceso.validacion,
            mensaje: 'Revisa',
            porCampo: {'username': 'Ese usuario ya existe.'},
          );
        final c = crear(a, _DronesFalso());
        await conTresFotos(c);
        await c.enviar(_persona, _dron);
        expect(c.state.erroresPorCampo['username'], 'Ese usuario ya existe.');
        expect(c.state.paso, PasoRegistro.cuenta);
        await c.close();
      },
    );
  });

  group('compresión de fotos', () {
    test('se detiene en la primera pasada que baja de 300 KB', () async {
      final pasadas = <(int, int)>[];
      final c = CompresorEvidenciaAdaptativo(
        pasada: (bytes, lado, calidad) async {
          pasadas.add((lado, calidad));
          return Uint8List(pasadas.length >= 2 ? 200 * 1024 : 400 * 1024);
        },
      );
      final r = await c.comprimir(Uint8List(5 * 1024 * 1024));
      expect(r.lengthInBytes, lessThan(topeBytesEvidencia));
      expect(pasadas, [(1280, 70), (1280, 55)]);
    });

    test(
      'si ninguna pasada alcanza, no sube una foto que el servidor rechaza',
      () async {
        final c = CompresorEvidenciaAdaptativo(
          pasada: (bytes, lado, calidad) async => Uint8List(400 * 1024),
        );
        await expectLater(
          c.comprimir(Uint8List(10)),
          throwsA(isA<FotoDemasiadoPesada>()),
        );
      },
    );
  });

  group('ubicación del piloto', () {
    test('no pide el permiso hasta que el piloto acepta compartir', () async {
      final servicio = ServicioUbicacionDemo();
      final repo = UbicacionDemo();
      final cubit = UbicacionCubit(servicio, repo, 10);
      await cubit.iniciar();
      // Sin permiso todavía: la pantalla explica el motivo y ofrece compartir.
      expect(cubit.state.fase, FaseUbicacion.denegada);
      expect(servicio.permiso, PermisoUbicacion.denegado);
      expect(repo.publicadas, isEmpty);
      await cubit.compartir();
      expect(cubit.state.fase, FaseUbicacion.compartiendo);
      await Future<void>.delayed(Duration.zero);
      expect(repo.publicadas, hasLength(1));
      cubit.detener();
      await cubit.close();
    });

    test(
      'con el permiso ya concedido empieza solo y publica cada intervalo',
      () async {
        final servicio = ServicioUbicacionDemo(
          permiso: PermisoUbicacion.concedido,
        );
        final repo = UbicacionDemo();
        final cubit = UbicacionCubit(
          servicio,
          repo,
          10,
          intervalo: const Duration(milliseconds: 20),
        );
        await cubit.iniciar();
        await Future<void>.delayed(const Duration(milliseconds: 90));
        expect(repo.publicadas.length, greaterThanOrEqualTo(3));
        cubit.detener();
        final n = repo.publicadas.length;
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(repo.publicadas.length, n);
        await cubit.close();
      },
    );

    test('un permiso bloqueado se explica y no publica', () async {
      final repo = UbicacionDemo();
      final cubit = UbicacionCubit(
        ServicioUbicacionDemo(permiso: PermisoUbicacion.denegadoParaSiempre),
        repo,
        10,
      );
      await cubit.iniciar();
      expect(cubit.state.fase, FaseUbicacion.denegadaParaSiempre);
      expect(repo.publicadas, isEmpty);
      await cubit.close();
    });
  });

  test('las fotos de avance usan la cámara y se guardan comprimidas', () async {
    final repo = EjecucionDemo();
    final cubit = ServicioLoteCubit(
      repo,
      10,
      AppLocalizationsEs(),
      selector: _SelectorFoto(),
    );
    cubit.iniciar();
    await Future<void>.delayed(Duration.zero);
    await cubit.tomarFotoDeAvance();
    expect(cubit.state.servicio!.fotosTotal, 3);
    expect(cubit.state.aviso, contains('Foto guardada'));
    await cubit.close();
  });
}

class _SelectorFoto implements SelectorFoto {
  @override
  Future<Uint8List?> tomarFoto() async => Uint8List.fromList([1, 2, 3]);
}
