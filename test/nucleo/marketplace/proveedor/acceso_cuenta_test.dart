// Acceso del piloto según el contrato de cuenta: `app` en el ingreso, `429`,
// `403 tipo_de_cuenta_incorrecto`, `409 cuenta_ya_registrada`, sesión
// restringida por eliminación, renovación al desbloquear y `siguiente_paso`.

import 'dart:typed_data';

import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:agrocom_field/nucleo/api/marketplace_http.dart';
import 'package:agrocom_field/nucleo/auth/biometria.dart';
import 'package:agrocom_field/nucleo/auth/bloqueo_biometrico.dart';
import 'package:agrocom_field/nucleo/auth/bloqueo_biometrico_store.dart';
import 'package:agrocom_field/nucleo/camara/selector_imagen.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/data/acceso_proveedor_red.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/domain/acceso_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/acceso_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/registro_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/data/cuenta_proveedor_red.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/domain/cuenta_proveedor.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../cliente/red/dobles_red.dart';

final _usuario = {'id': 9, 'name': 'Carlos Mamani', 'username': 'carlos'};

Map<String, dynamic> _token(String rol) => {
  'token': 'abc',
  'usuario': _usuario,
  'rol': {'id': 7, 'name': rol},
};

final _persona = DatosPersona(
  nombres: 'Carlos',
  apellidos: 'Mamani',
  documentoIdentidad: '123',
  fechaNacimiento: DateTime(1990),
  telefono: '70012345',
  usuario: 'carlos.mamani',
  contrasena: 'abcd',
  licenciaNumero: 'L-1',
  licenciaVence: DateTime(2027),
  categoriaHabilitacion: 'A',
);

void main() {
  group('AccesoProveedorRed según el contrato de cuenta', () {
    late EntornoRed e;
    late AccesoProveedorRed acceso;

    setUp(() {
      e = EntornoRed(token: null);
      acceso = AccesoProveedorRed(
        api: e.api,
        tokenStore: e.tokens,
        dispositivoStore: DispositivoFijo(),
        rolesPreferidos: const ['proveedor', 'piloto'],
        nombreDispositivo: 'Agrocom Piloto',
      );
      e.servidor.responder('DELETE', '/api/auth/token', codigo: 204);
    });

    test('el ingreso declara la app piloto', () async {
      e.servidor.responder(
        'POST',
        '/api/auth/token',
        codigo: 201,
        cuerpo: _token('proveedor'),
      );
      await acceso.iniciarSesion(usuario: '70012345', contrasena: 'abcd');
      final cuerpo =
          e.servidor.de('POST', '/api/auth/token').single.cuerpo! as Map;
      expect(cuerpo['app'], 'piloto');
    });

    test('429 se distingue de una contraseña errada', () async {
      e.servidor.responder('POST', '/api/auth/token', codigo: 429, cuerpo: {});
      await expectLater(
        acceso.iniciarSesion(usuario: 'x', contrasena: 'y'),
        throwsA(
          isA<AccesoProveedorExcepcion>().having(
            (x) => x.motivo,
            'motivo',
            MotivoFalloAcceso.demasiadosIntentos,
          ),
        ),
      );
    });

    test(
      '403 tipo_de_cuenta_incorrecto muestra el texto del servidor',
      () async {
        e.servidor.responder(
          'POST',
          '/api/auth/token',
          codigo: 403,
          cuerpo: {
            'message': 'Esta cuenta es de cliente: ingresa en la app Agrocom.',
            'codigo': 'tipo_de_cuenta_incorrecto',
            'tipo_cuenta': 'cliente',
          },
        );
        await expectLater(
          acceso.iniciarSesion(usuario: 'x', contrasena: 'y'),
          throwsA(
            isA<AccesoProveedorExcepcion>()
                .having(
                  (x) => x.motivo,
                  'motivo',
                  MotivoFalloAcceso.cuentaAjena,
                )
                .having((x) => x.mensaje, 'mensaje', contains('app Agrocom.')),
          ),
        );
      },
    );

    test('409 cuenta_ya_registrada no crea nada', () async {
      e.servidor.responder(
        'POST',
        '/api/proveedores/registro',
        codigo: 409,
        cuerpo: {
          'message': 'Ya tienes una cuenta.',
          'codigo': 'cuenta_ya_registrada',
          'tipo_cuenta': 'proveedor',
        },
      );
      await expectLater(
        acceso.registrar(_persona),
        throwsA(
          isA<AccesoProveedorExcepcion>()
              .having(
                (x) => x.motivo,
                'motivo',
                MotivoFalloAcceso.cuentaYaRegistrada,
              )
              .having((x) => x.tipoCuenta, 'tipoCuenta', 'proveedor'),
        ),
      );
    });

    test('una cuenta con eliminación vigente entra restringida', () async {
      e.servidor
        ..responder(
          'POST',
          '/api/auth/token',
          codigo: 201,
          cuerpo: _token('proveedor'),
        )
        ..responder(
          'GET',
          '/api/cuenta/eliminacion',
          cuerpo: {
            'eliminacion': {
              'estado': 'solicitada',
              'solicitada_en': '2026-11-27T12:00:00Z',
              'ejecutar_desde': '2026-12-04T12:00:00Z',
            },
            'impedimentos': <String>[],
          },
        );
      final s = await acceso.iniciarSesion(
        usuario: 'carlos',
        contrasena: 'abcd',
      );
      expect(s.enEliminacion, isTrue);
      expect(e.tokens.token, 'abc');
    });

    test('sin eliminación vigente la sesión es normal', () async {
      e.servidor
        ..responder(
          'POST',
          '/api/auth/token',
          codigo: 201,
          cuerpo: _token('proveedor'),
        )
        ..responder(
          'GET',
          '/api/cuenta/eliminacion',
          cuerpo: {'eliminacion': null, 'impedimentos': <String>[]},
        );
      final s = await acceso.iniciarSesion(
        usuario: 'carlos',
        contrasena: 'abcd',
      );
      expect(s.enEliminacion, isFalse);
    });
  });

  group('AccesoCubit', () {
    late BiometriaFalsa biometria;
    late BloqueoBiometricoStoreEnMemoria store;
    late BloqueoBiometrico bloqueo;

    setUp(() {
      biometria = BiometriaFalsa();
      store = BloqueoBiometricoStoreEnMemoria(activo: true);
      bloqueo = BloqueoBiometrico(biometria, store);
    });

    test('al desbloquear con la biometría renueva la sesión', () async {
      var renovaciones = 0;
      final c = AccesoCubit(
        _Acceso()..sesion = _sesion(),
        AppLocalizationsEs(),
        bloqueo: bloqueo,
        renovarSesion: () async {
          renovaciones++;
          return true;
        },
      );
      await c.iniciar();
      expect(renovaciones, 1);
      expect(c.state, isA<AccesoDentro>());
      await c.close();
    });

    test('cancelar la biometría no renueva ni entra', () async {
      biometria.resultado = ResultadoBiometria.cancelado;
      var renovaciones = 0;
      final c = AccesoCubit(
        _Acceso()..sesion = _sesion(),
        AppLocalizationsEs(),
        bloqueo: bloqueo,
        renovarSesion: () async {
          renovaciones++;
          return true;
        },
      );
      await c.iniciar();
      expect(renovaciones, 0);
      expect(c.state, isA<AccesoBloqueado>());
      await c.close();
    });

    test(
      'un 429 deja una cuenta regresiva y luego permite reintentar',
      () async {
        final acceso = _Acceso()
          ..falla = const AccesoProveedorExcepcion(
            MotivoFalloAcceso.demasiadosIntentos,
            esperaSegundos: 3,
          );
        final c = AccesoCubit(
          acceso,
          AppLocalizationsEs(),
          pasoEspera: const Duration(milliseconds: 4),
        );
        await c.ingresar('x', 'y');
        final espera = c.state as AccesoSinSesion;
        expect(espera.enEspera, isTrue);
        expect(espera.mensaje, contains('Podrás volver a intentarlo en'));

        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect((c.state as AccesoSinSesion).enEspera, isFalse);
        await c.close();
      },
    );

    test(
      'una sesión en eliminación va a su pantalla y se puede conservar',
      () async {
        final acceso = _Acceso()
          ..sesion = const SesionProveedor(
            nombre: 'Carlos',
            usuario: 'carlos',
            rol: 'proveedor',
            enEliminacion: true,
          );
        final c = AccesoCubit(acceso, AppLocalizationsEs());
        await c.iniciar();
        expect(c.state, isA<AccesoEnEliminacion>());

        // «Conservar mi cuenta»: la sesión ya no viene restringida.
        acceso.sesion = _sesion();
        await c.cuentaConservada();
        expect(c.state, isA<AccesoDentro>());
        await c.close();
      },
    );

    test(
      'al ingresar con una cuenta en eliminación no entra a la app',
      () async {
        final acceso = _Acceso()..enEliminacion = true;
        final c = AccesoCubit(acceso, AppLocalizationsEs());
        await c.ingresar('carlos', 'abcd');
        expect(c.state, isA<AccesoEnEliminacion>());
        await c.close();
      },
    );
  });

  group('alta del proveedor', () {
    test(
      'un 409 muestra «Ya tienes una cuenta» y no sigue con el alta',
      () async {
        final acceso = _Acceso()
          ..falla = const AccesoProveedorExcepcion(
            MotivoFalloAcceso.cuentaYaRegistrada,
            tipoCuenta: 'proveedor',
          );
        final drones = _Drones();
        final c = RegistroCubit(
          acceso: acceso,
          drones: drones,
          selector: _Selector(),
          compresor: _Compresor(),
          l10n: AppLocalizationsEs(),
        );
        await c.enviar(
          _persona,
          DatosDron(
            marca: 'DJI',
            modelo: 'T40',
            numeroSerie: 'S',
            capacidadTanqueL: Decimal.parse('40'),
            anchoPasadaM: Decimal.parse('11'),
          ),
        );
        expect(c.state.cuentaExistente, isTrue);
        expect(c.state.tipoCuentaExistente, 'proveedor');
        expect(c.state.mensaje, isNull);
        expect(c.state.enviando, isFalse);
        expect(drones.llamadas, isEmpty);
        await c.close();
      },
    );
  });

  group('siguiente_paso de /api/proveedores/mi', () {
    Future<EstadoCuentaProveedor> leer(Map<String, dynamic> extra) async {
      final e = EntornoRed();
      e.servidor.responder(
        'GET',
        '/api/proveedores/mi',
        cuerpo: {
          'proveedor': {'id': 3, 'estado': 'pendiente'},
          'documentos_faltantes': ['identidad'],
          'apto_para_ofertas': false,
          'disponibilidad': {'valor': 'disponible'},
          'disponibilidad_empresa': {'valor': 'disponible'},
          ...extra,
        },
      );
      return CuentaProveedorRed(MarketplaceHttp(e.api)).estado();
    }

    test('subir_documentos: se continúa subiendo lo que falta', () async {
      final c = await leer({'siguiente_paso': 'subir_documentos'});
      expect(c.siguientePaso, SiguientePasoProveedor.subirDocumentos);
      expect(c.debeSubirDocumentos, isTrue);
      expect(c.debeCorregir, isFalse);
    });

    test('corregir: se reenvía a revisión', () async {
      final c = await leer({
        'proveedor': {'id': 3, 'estado': 'rechazado'},
        'documentos_faltantes': <String>[],
        'siguiente_paso': 'corregir',
      });
      expect(c.debeCorregir, isTrue);
      expect(c.debeSubirDocumentos, isFalse);
    });

    test('en_revision: nada que hacer, solo esperar', () async {
      final c = await leer({
        'documentos_faltantes': <String>[],
        'siguiente_paso': 'en_revision',
      });
      expect(c.debeCorregir, isFalse);
      expect(c.debeSubirDocumentos, isFalse);
    });

    test('sin siguiente_paso se deduce del estado (compatibilidad)', () async {
      final c = await leer({});
      expect(c.siguientePaso, isNull);
      expect(c.debeSubirDocumentos, isTrue);
    });

    test('un valor desconocido se ignora y manda el estado', () async {
      final c = await leer({'siguiente_paso': 'algo_nuevo'});
      expect(c.siguientePaso, isNull);
      expect(c.debeSubirDocumentos, isTrue);
    });
  });
}

SesionProveedor _sesion() => const SesionProveedor(
  nombre: 'Carlos',
  usuario: 'carlos',
  rol: 'proveedor',
);

class _Acceso implements AccesoProveedorRepositorio {
  SesionProveedor? sesion;
  Object? falla;
  bool enEliminacion = false;

  @override
  Future<SesionProveedor?> sesionActual() async => sesion;

  @override
  Future<SesionProveedor> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
    return sesion = SesionProveedor(
      nombre: 'Carlos',
      usuario: usuario,
      rol: 'proveedor',
      enEliminacion: enEliminacion,
    );
  }

  @override
  Future<void> registrar(DatosPersona datos) async {
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
  }

  @override
  Future<void> cerrarSesion() async => sesion = null;
}

class _Drones implements RegistroDronesRepositorio {
  final llamadas = <String>[];

  @override
  Future<int> registrarDron(DatosDron datos) async {
    llamadas.add('dron');
    return 1;
  }

  @override
  Future<void> subirFoto(int dronId, FotoDronLista foto) async =>
      llamadas.add('foto');
}

class _Selector implements SelectorImagen {
  @override
  Future<Uint8List?> tomarFoto() async => Uint8List.fromList([1]);

  @override
  Future<Uint8List?> elegirDeGaleria() async => Uint8List.fromList([2]);
}

class _Compresor implements CompresorEvidencia {
  @override
  Future<Uint8List> comprimir(Uint8List bytes) async => bytes;
}
